import gspread, csv
from oauth2client.service_account import ServiceAccountCredentials
import pandas as pd
from configparser import ConfigParser

#Read config.cfg file
config_object = ConfigParser()
config_object.read("config.cfg")

#Get the python variables
gsheet_info = config_object["GSHEET_VARS"]

scope = ["https://spreadsheets.google.com/feeds",'https://www.googleapis.com/auth/spreadsheets',"https://www.googleapis.com/auth/drive.file","https://www.googleapis.com/auth/drive"]
creds = ServiceAccountCredentials.from_json_keyfile_name("src/keys.json", scope) # Google API key from file
client = gspread.authorize(creds) #Oauth2 to GAPI
sheet = client.open(gsheet_info["SAMPLE_SPREADSHEET_NAME"].strip('"')).sheet1  # Open the spreadhseet
data = sheet.get_all_records()  # Get a list of all records

std_list = pd.read_json(r'res/studies.json').to_csv(r'res/studies.csv', index = None, header=True)
std_sum = pd.read_json(r'res/studies_sumary.json').fillna(0).astype(int).to_csv(r'res/studies_sumary.csv')
pd.read_csv('res/studies_sumary.csv', header=None).T.to_csv('res/studies_sumary.csv', header=False, index=False)

with open('res/studies_sumary.csv', newline='') as f:
    reader = csv.reader(f)
    data = list(reader)
    sheet.update('A2', data)

with open('res/studies.csv', newline='') as f:
    reader = csv.reader(f)
    data = list(reader)
    sheet.update('A10', data)
