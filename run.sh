#!/bin/bash
coffee -wc ./server/public &
nodemon app.js "$@"
