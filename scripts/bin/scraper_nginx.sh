#!/bin/bash

# ==============================================================================
# Bash Script to Download Books with HTTP Basic Authentication
# ==============================================================================
#
# This script automates the download of a specific list of PDF files
# from a password-protected Nginx server.
#
# Instructions:
# 1. Replace "YOUR_USERNAME" and "YOUR_PASSWORD" with your actual credentials.
# 2. Make the script executable: chmod +x download_books.sh
# 3. Run the script: ./download_books.sh

# wget --user="hello" --password="" -r -np -nH --cut-dirs=3 -A pdf -P other http://10.8.5.22/books/

# --- Configuration ---
# Your username for HTTP Basic Authentication
username="hello"

# Your password for HTTP Basic Authentication
password=""

# The base URL for the books directory
base_url="http://10.8.5.22/books/oreillybooksarchitecture"

# List of all the book filenames you want to download
files=(
  "architecturepatternswithpython.pdf"
  "continuousapimanagement2e.pdf"
  "fundamentalsofenterprisearchitecture.pdf"
  "securityandmicroservicearchitectureonaws.pdf"
  "buildinganevent-drivendatamesh.pdf"
  "datamesh.pdf"
  "fundamentalsofsoftwarearchitecture2e.pdf"
  "softwarearchitectelevator.pdf"
  "buildingevolutionaryarchitectures2e.pdf"
  "decipheringdataarchitectures.pdf"
  "headfirstsoftwarearchitecture.pdf"
  "softwarearchitecture_thehardparts.pdf"
  "buildingmicroservices2e.pdf"
  "designingdistributedsystems2e.pdf"
  "learningdomain-drivendesign1e.pdf"
  "softwarearchitecturemetrics.pdf"
  "buildingmulti-tenantsaasarchitectures.pdf"
  "facilitatingsoftwarearchitecture.pdf"
  "learningsystemsthinking.pdf"
  "cloudapplicationarchitecturepatterns.pdf"
  "flowarchitectures.pdf"
  "masteringapiarchitecture.pdf"
  "communicationpatterns.pdf"
  "foundationsofscalablesystems.pdf"
  "monolithtomicroservices.pdf"
)

# --- Download Loop ---
# Loop through each filename in the 'files' array
for file in "${files[@]}"; do
  echo "Downloading: ${file}"

  # Use curl to download the file. The -u flag provides the username and password.
  # The -O flag saves the file with the same name as the remote file.
  curl -s --fail -u "$username:$password" -O "${base_url}/${file}"

  # Uncomment the line below to use wget instead of curl.
  # wget --user="$username" --password="$password" "${base_url}/${file}"

  # Check if the download was successful
  if [ $? -eq 0 ]; then
    echo "Successfully downloaded ${file}"
  else
    echo "Failed to download ${file}"
  fi
  echo "---"
done

echo "All downloads attempted."
