#!/bin/bash

today=`date +%F`
before_yesterday=`date -d "-2 day" +%F`

echo ${today}
echo ${before_yesterday}
