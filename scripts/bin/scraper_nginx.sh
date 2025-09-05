#!/bin/bash

wget --user="hello" --password="friend" -r -np -nH --cut-dirs=3 -A pdf -P other http://10.8.5.22/books/
