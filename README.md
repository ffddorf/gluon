ae:
Wie baut man "meine" Version:



    git clone git@github.com:aeickho/gluon.git
    cd gluon
    git submodule init
    git submodule update

dann site/site.mk die versionskennung anpassen ...  z.B 0.7.xx.01

    make update
    make BROKEN=1  <- damit es auch den WNDRMAC baut

und dann warten

und wie mache ich es:

    git clone git@github.com:aeickho/gluon.git

    cd gluon

    git submodule init
    git submodule update

    cd site
    
dann site.mk die versionskennung anpassen ...  z.B 0.7.xx.01

    git commit -a site.mk
    git push

    cd ..
    git commit -a   # damit die neue commit id des submodules aktualiesiert wird
    git push


    make update
    make BROKEN=1  <- damit es auch den WNDRMAC baut


----------------------------------------------


Documentation (incomplete at this time, contribute if you can!) may be found at
http://gluon.readthedocs.org/

If you're new to Gluon and ready to get your feet wet, have a look at the
[Getting Started Guide](http://gluon.readthedocs.org/en/latest/user/getting_started.html).

**Gluon IRC channel: `#gluon` in [hackint](http://hackint.org/)**

## Issues & Feature requests

Before opening an issue make sure to read check whether any existing issues
(open or closed) match. If you're suggesting a new feature, drop by on IRC or
our mailinglist to discuss it first.

## Use a release!

Please refrain from using the master branch for anything else but development purposes!
Use the most recent release instead. You can list all relaseses by running `git branch -a`
and switch to one by running `git checkout v2014.4;make update`.

If you're using the autoupdater, do not autoupdate nodes with anything but releases.
If you upgrade using random master commits the nodes *will break* eventually.

## Mailinglist

To subscribe to the list, send a message to:

    gluon-subscribe@luebeck.freifunk.net

To remove your address from the list, just send a message to
the address in the `List-Unsubscribe` header of any list
message. If you haven't changed addresses since subscribing,
you can also send a message to:

    gluon-unsubscribe@luebeck.freifunk.net
