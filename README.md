cs61c-version-control
=====================

Wrapper around git specific to Berkeley's CS61C class

To configure, add both cs and cs.sh to a directory in your $PATH (they must be in the same directory as one another)<br>
In the same directory, create a file called .csconfig, which should look something like this:


\#!/bin/bash

export PATH61C="${HOME}/Desktop/cs61c"<br>
export SERVER="cs61c-XX@torus.cs.berkeley.edu"

$PATH61C should be a directory that you want to use as the root directory for your assignments. Directories for hw and proj will be automatically created if necessary.
