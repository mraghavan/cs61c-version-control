cs61c-version-control
=====================

Wrapper around git specific to Berkeley's CS61C class

To configure, add both cs and cs.sh to a directory in your path (they must be in the same directory)

In the same directory, create a file called .csconfig, which should look something like this:


#!/bin/bash

export PATH61C="${HOME}/Desktop/cs61c"
export SERVER="cs61c-XX@torus.cs.berkeley.edu"
