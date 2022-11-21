# Executable

Trying to build an executable that works on both Windows and Linux.

So far:
* OCRA doesn't seem to build, expects a lower Ruby version
* ruby-packer () also seems to be failing - getting "No such file or directory @ rb_sysopen Errno::ENOENT with libruby.so.3.0.2"
* Glimmer has a package command, but it's jruby based.
* mruby?