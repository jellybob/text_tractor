# Copycat #

Copycat is an Open Source implementation of Copycopter's API, and web interface to allow clients to
edit the copy on their websites. It's designed to be compatible with the copycopter_client gem.

## Legal Disclaimer ##

I have no idea how legal this is. I'm fairly sure that implementing somebody else's API isn't covered
by copyright law, but it's possible there are either patents, or clauses under DMCA which makes using
this software illegal where you live. I take no responsibility if Thoughtbot come knocking on your door
with a lawyer.

Having said that, somebody implemented support for the Hoptoad client in Redmine, so there's at least some
precedent for them not prosecuting people.

## Why Rebuild Copycopter? ##

That would be a legitimate question. Here are my reasons:

* I didn't like Thoughtbot's web interface. Most of my clients would have a fit if they had to use it.
* I don't it's worth spending up to $540/year for.
* I had a free day, and wanted to try out Redis in a real application.

## Making it Work ##

Copycat is designed to be deployed to Heroku, and has a config.ru already in place to do so. You'll need to
add one of the Redis to Go addons to your application, after which you should be good to go. Just `git push heroku`.

Once you do that you'll be able to access the web interface. Unless you've changed the defaults in config.ru the default
username and password is "admin", and "password". You should change the defaults.

To create your first project hit the big "New Project" button, and give it a name. You'll then be presented with some
instructions on setting up your application to use Copycat for it's copy. Once you've finished doing that, and some content
has been uplaoded, you'll be able to see it.

To edit some content, find it by browsing through the tree (this is the big difference to Copycopter), and edit away.

Currently Copycat only supports publishing content in one go using the `copycopter:deploy` rake task from your application, if
you want support for publishing individual pieces of content then you'll need to submit a patch unless I end up with a client who
wants that feature. (That client could be you if you really want it.)

If you're deploying this on your own server, keep in mind that it requires Ruby 1.9.2 (I might relax that requirement if there's
enough demand, but it makes the syntax in the views much cleaner).

## Contributing ##

If you want to contribute, fork this repository, and submit a pull request when you're done. I won't accept patches which don't
come with accompanying tests, but I am quite happy to help you write those tests if it's not something you're used to doing.

## Licensing ##

Copycat is developed by Blank Pad Development (http://blankpad.net), and released under the MIT License. As stated earlier, I
take no responsibility for Thoughtbot sueing you.
