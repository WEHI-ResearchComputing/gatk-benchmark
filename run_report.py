import sqlite3
import argparse
import sys
import os
from subprocess import Popen, PIPE
import datetime
import traceback
from prettytable import PrettyTable

SACCT = 'sacct --format JobID,Elapsed,AveDiskRead,AveDiskWrite,NCPUS,TotalCPU --parsable2 --noheader --allusers --jobs'

class Job:
  @staticmethod
  def _parse_timedelta(s, format_string):
    try:
      t = datetime.datetime.strptime(s, format_string)
      return datetime.timedelta(hours=t.hour, minutes=t.minute, seconds=t.second)
    except ValueError:
      print(s)
      return None

  @staticmethod
  def from_csv_line(line):
    words = line.split('|')
    if len(words) < 6:
      return None
    
    try:
      job_id = words[0].split('.')[0]
      elapsed = Job._parse_timedelta(words[1], '%H:%M:%S')
      read_bytes = words[2]
      write_bytes = words[3]
      n_cpus = words[4]
      cput = words[5]
      if '.' in cput:
        cpu_time = Job._parse_timedelta(words[5].split('.')[0], '%M:%S')
      else:
        cpu_time = Job._parse_timedelta(words[5], '%H:%M:%S')
    except Exception as e:
      print(words)
      print(e)
      traceback.print_exc(e)
      quit()

    return Job(job_id, elapsed, read_bytes, write_bytes, n_cpus, cpu_time)

  def __init__(self, job_id, elapsed, read_bytes, write_bytes, n_cpus, cpu_time):
    (self.job_id, self.elapsed, self.read_bytes, self.write_bytes, self.n_cpus, self.cpu_time) = job_id, elapsed, read_bytes, write_bytes, n_cpus, cpu_time

  def update_table(self, t):
    #   t.field_name = ['Name', 'Job id', 'Elapsed', 'CPUs', 'CPU time', 'Read bytes', 'Write bytes']
    t.add_row([self.name, self.job_id, self.elapsed.total_seconds(), self.n_cpus, self.cpu_time.total_seconds(), self.read_bytes, self.write_bytes])

def parser():
  parser = argparse.ArgumentParser()
  parser.add_argument('--task-db',
                      dest='task_db',
                      help='The task database',
                      required=True
                      )
  return parser

def get_jobids(task_db):
  conn = sqlite3.connect(task_db)
  c = conn.cursor()
  jobs = {}
  for name, id in c.execute('SELECT jid, batchid FROM jobs'):
    if id:
      jobs[str(id)] = name
  return jobs

def add_job_info(jids):
  cmd = SACCT + ' ' + '.batch,'.join(jids.keys()) + '.batch'
  p = Popen(cmd.split(), stdout=PIPE)
  o, _ = p.communicate()
  lines = o.decode('utf-8').split('\n')
  jobs = []
  for line in lines:
    j = Job.from_csv_line(line)
    if j:
      j.name = jids[j.job_id]
      jobs.append(j)
  return jobs

def main():
  args = parser().parse_args()
  task_db = args.task_db
  jobs = get_jobids(task_db)
  jobs = add_job_info(jobs)
  
  t = PrettyTable()
  t.field_names = ['Name', 'Job id', 'Elapsed', 'CPUs', 'CPU time', 'Read bytes', 'Write bytes']
  for j in jobs:
    j.update_table(t)
  print(t)


if __name__== '__main__':
  main()