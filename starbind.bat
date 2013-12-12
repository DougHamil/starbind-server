@echo off
@SETLOCAL ENABLEEXTENSIONS
@cd /d "%~dp0"
SET PATH=%PATH%;PortableGit\bin
node.exe server.js