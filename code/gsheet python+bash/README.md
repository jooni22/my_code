# Required Library

## Main
- Python3
- jq

## Python library
- google-api-python-client
- google-auth-httplib2
- google-auth-oauthlib
- gspread
- oauth2client
- pandas

# Links:
https://developers.google.com/sheets/api/quickstart/python
https://gspread.readthedocs.io/en/latest/
https://github.com/burnash/gspread
https://www.youtube.com/watch?v=4ssigWmExak
# Files in project
.
├── bin
│   └── jq
├── config.cfg
├── dashboard.sh
├── log.txt
├── README.md
├── res ##################### After first run
│   ├── dashboard.json
│   ├── studies.csv
│   ├── studies.json
│   ├── studies_sumary.csv
│   └── studies_sumary.json
└── src
    ├── keys.json
    ├── sheet_update.py
    └── study-dashboard.xqy

# How to run?
chmod a+x dashboard.sh
OR
chmod a+x -R .
THEN
./dashboard.sh

Status and errors located in log.txt
