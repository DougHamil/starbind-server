#!/bin/bash
coffee -wc ./public &
nodemon app.js "$@"
