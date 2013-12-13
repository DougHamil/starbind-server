#!/bin/bash
coffee -wc ./public &
nodemon server.coffee "$@"
