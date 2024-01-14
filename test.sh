#!/bin/bash

                        if [ $(nmcli device status | grep connected | grep eth3 | wc -l) -ne 0 ];
                        then
                        echo test
                        else
                        echo else
                        fi

