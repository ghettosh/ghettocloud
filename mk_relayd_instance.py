#!/usr/bin/env python

import sqlite3
import os
import sys
from pprint import pprint
from random import choice

dbfile = '/data/serve/ghettoapi/cgi/ghetto.db'
relayd_configs = '/data/serve/relayd_instances/'

customers = []
relayd_map = {}
debug = False

def usage():
  print """

  {me}
  {ul}
  example relayd configurator

  Description
  -----------
  Inspects the sqlite database for ghettocloud and creates relayd instances
  based off of live hosts, and hostnames

  How to use
  ----------
  Simply run {me}, it will examine the database and build relayd configurations
  for all available vms. The master relayd gets an 'include' line pointing to
  a configuation file in {cnf}

""".format(me=sys.argv[0], ul=( len(sys.argv[0]) * '-' ), cnf=relayd_configs) 
  sys.exit(1)

if len(sys.argv) > 1:
  usage()

try:                                                                            
  db = sqlite3.connect(dbfile)
except:                                                                         
  print "FATAL: couldn't open db file"  

sql = '''SELECT hostname, ip FROM vms where hostname NOT NULL;''' 
if debug: print "\nDEBUG: Executing sql: {s}\n".format(s=sql)

cursor = db.cursor()                                                          
cursor.execute(sql)                                                         
vms = cursor.fetchall()
db.close()

if debug: print "\nDEBUG: variable vms populated with: {v}\n".format(v=vms)

for vm in vms:
  (hostname,ip) = vm
  if '-' not in hostname:
    continue
  else:
    customer = hostname.split('-')[0]
  if customer not in customers:
    customers.append(customer)


for cust in customers:
  vmlist = []
  for vm in vms:
    if vm[0].startswith(cust):
      if debug:
        print "DEBUG: adding vm: {vm}({ip}) to cust {c}".format(vm=vm[0],
                                                         ip=vm[1],
                                                         c=cust)
      vmlist.append(vm[1])
  relayd_map[cust] = vmlist
      

if debug: 
  print "\nDEBUG: relayd_map dict contains:"
  pprint(relayd_map)
  print "\n"


print "INFO: Unique customers: {c}".format(c=', '.join(customers))
for cust in customers:
  relayd_master_config = '/etc/relayd.conf'
  relayd_config_file = relayd_configs + cust + '.conf'
  if not os.path.isfile(relayd_config_file):
    fh = open(relayd_config_file, 'w')
    relayd_config = "ext_addr=\"24.8.187.39\"\n"
    counter = 0
    for e in relayd_map[cust]:
      whstr = 'webhost{c}="{e}"\n'.format(c=counter,e=e)
      counter+=1
      port = choice(range(1024,4096))
      relayd_config += whstr

    relayd_config += '''
table <webhosts-%s> { $webhost0 $webhost1 $webhost2 $webhost3 }
redirect etcd-%s {
        listen on $ext_addr port %s 
        tag RELAYD
        forward to <webhosts-%s> port 4001 check icmp
}
''' % (cust,cust,port,cust)
    servers = ' '.join(relayd_map[cust])
    print "INFO: writing relayd configuration {f}".format(f=relayd_config_file)
    fh.write(relayd_config)
    fh.close()

  master_conf = open(relayd_master_config, 'r+')
  if relayd_config_file not in master_conf.read():
    print "INFO: Adding line to relayd master config"
    include_line = 'include "{f}"\n'.format(f=relayd_config_file)
    if debug: print "DEBUG: Writing include line: %s" % include_line
    master_conf.write(include_line)
  master_conf.close()
  print "INFO: Completed configuration for customer %s" % cust

print "INFO: Done"
