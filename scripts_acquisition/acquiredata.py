# Authors:
# Antonia Elsen (aelsen)
#
# This script is modified and extended from a [prexisting]. The original author is github user 'dzhu'.
# Dzhu's repository can be found online at 'https://github.com/dzhu/myo-raw'.


from __future__ import print_function

import re
import struct
import sys
import threading
import os
import errno
import time
import datetime
from datetime import *

import serial
from serial.tools.list_ports import comports

from common import *
from MyoBT import *
from MyoRaw import *

maxsamples = 8
samplelength = 3

def makeFile(samplenum, fn_gesture, fn_volunteer):
    # Specify file name, open file
    dirname = "data/" + fn_gesture + "/" + fn_volunteer + "/"
    filename = "S" + str(s) + "_" + time.strftime("%m-%d-%H_%M_%S") + ".csv"
    try:
        os.makedirs(dirname)
    except OSError:
        if not os.path.isdir(dirname):
            raise

    df = open(dirname+filename, 'a')
    print("Writing to file \""+dirname+filename+"\".")
    return df
    

if __name__ == '__main__':
    ## Create file for data - specify volunteer and gesture name
    os.system('cls' if os.name == 'nt' else 'clear')
    volunteer = raw_input('Enter volunteer name: ')
    gesture = raw_input('Enter gesture name: ')
    
    
    ## Loop a specified number of times, to collect multimple samples of the same gesture
    for s in range(1,maxsamples+1):
        f = makeFile (s, gesture, volunteer)
#        os.system('cls' if os.name == 'nt' else 'clear')
        print("########## TAKING SAMPLE " + str(s)+ " OF " + str(maxsamples) + " ###########")
        isReady = raw_input('Please hit enter when ready.')
        print("Preparing to read...")
        time.sleep(1)
         # Initialize, connect to Myo
        m = MyoRaw(sys.argv[1] if len(sys.argv) >= 2 else None)
        def proc_emg(emg, moving, times=[]):
                datas = datetime.now().strftime('%H:%M:%S:%f,') + ','.join(map(str, emg)) ## Convert data tuple to string, removing parens
                ## save data to file, print to console
                f.write(datas+"\n")
                print(datas)

                ## print framerate of received data
                times.append(time.time())
        m.add_emg_handler(proc_emg)
        m.connect()
        m.add_arm_handler(lambda arm, xdir: print('arm', arm, 'xdir', xdir))
        m.add_pose_handler(lambda p: print('pose', p))
        
        # Track the elapsted time
        tdelta = timedelta(seconds = samplelength)
        starttime = datetime.now()
        currenttime = starttime
        
        try:
            while (currenttime - starttime) <= tdelta:
                m.run(1)
                currenttime =  datetime.now()
        except KeyboardInterrupt:
            pass
        finally:
            print()
            m.disconnect()
            f.close()
            
    
    print("Thanks!")
    print()
