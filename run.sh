#!/bin/bash
npm install
coffee -wc ./public &
nodemon server.coffee
