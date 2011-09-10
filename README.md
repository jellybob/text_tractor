# TextTractor #

This project will be changing it's name just as soon as I can think of a new one, after Thoughtbot
(quite legitimately) requested that I remove the word "copy" from the name, as it's a part of their
trademark.

TextTractor is an Open Source implementation of Copycopter's API, and web interface to allow clients to
edit the copy on their websites. It's designed to be compatible with the copycopter_client gem.

## Why Rebuild Copycopter? ##

That would be a legitimate question. Here are my reasons:

* I didn't like Thoughtbot's web interface. Most of my clients would have a fit if they had to use it.
* I don't it's worth spending up to $540/year for.
* I had some free time, and wanted to try out Redis in a real application.

Currently the web interface needs some polish, but it does work.

## Making it Work ##

TextTractor is designed to be deployed to Heroku, and has a config.ru already in place to do so. You'll need to
add one of the Redis to Go addons to your application, after which you should be good to go. Just `git push heroku`.

Once you do that you'll be able to access the web interface. Unless you've changed the defaults in config.ru the default
username and password is "admin", and "password". You should change the defaults.

You should probably also change the settings for where you're hosted, but that's not essential. If you don't change the
settings then the instructions you get for setting up a new project will be wrong though.

To create your first project hit the big "New Project" button, and give it a name. You'll then be presented with some
instructions on setting up your application to use TextTractor for it's copy. Once you've finished doing that, and some content
has been uplaoded, you'll be able to see it.

To edit some content, find it by browsing through the tree (this is the big difference to Copycopter), and edit away.

Currently TextTractor only supports publishing content in one go using the `copycopter:deploy` rake task from your application, if
you want support for publishing individual pieces of content then you'll need to submit a patch unless I end up with a client who
wants that feature. (That client could be you if you really want it.)

If you're deploying this on your own server, keep in mind that it requires Ruby 1.9.2 (I might relax that requirement if there's
enough demand, but it makes the syntax in the views much cleaner).

## Contributing ##

If you want to contribute, fork this repository, and submit a pull request when you're done. I won't accept patches which don't
come with accompanying tests, but I am quite happy to help you write those tests if it's not something you're used to doing.

## Things to be Done ##

* Mark which phrases have been published in the web interface.
* Add some filtering to the web interface. Currently it just dumps the complete list on the screen at once.
* Allow publishing from the web interface.

## Thanks ##

Thank you to Thoughtbot, who other then requesting that I change the project's name from it's original one,
which was purposely similar to Copycopter, have been incredibly accomodating towards me providing a method
for people to avoid paying them money.

You should go and sign up for either [Hoptoad](http://hoptaodapp.com) or [Tracjectory](http://apptrajectory.com), both which
I highly recommend.

## Licensing ##

TextTractor is developed by Blank Pad Development (http://blankpad.net), and released under the MIT License.
