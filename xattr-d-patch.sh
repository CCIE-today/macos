#!/bin/bash

sudo xattr -d $(xattr -l $1 | cut -f 1 -d :) $1