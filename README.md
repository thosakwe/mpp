# mpp
Git-based, password-protected private Pub server.

`mpp` is pretty minimal, and requires setup, but gets the job done.

`mpp` is built using
[Angel](https://angel-dart.dev),
a powerful, production-ready backend framework
in Dart. Consider checking it out if you like `mpp`.

## How it works
`mpp` is a bare-minimum implementation of the Pub server API. It can be
configured to fetch package sources from remote Git URL's, and redirects any
other request to `https://pub.dartlang.org`.

For example, if you set up `hello` to mirror `https://github.com/hello/foo`, then
you can include `package:hello` in your own packages, provided that you set up
Pub correctly (either via `PUB_HOSTED_URL`, or explicit `hosted` dependencies.)

`mpp` is password-protected, so third parties and malicious parties have no access to
your private Dart code. For this to work, `mpp` requires `Basic` authentication.

For example, if you have a user `foo` with password `bar`, and `mpp` is running at
`localhost:3000`, you could run the following:

```bash
export PUB_HOSTED_URL=http://foo:bar@localhost:3000
```

And then commands like `pub get` and `pub upgrade` would work, seamlessly.

## Installation
```
pub global activate mpp
```

## Usage
`mpp` is not a globally-installed package, so expect to the following generated
in the *working directory*:
* `.dart_tool/mpp_packages`
* `repos.json`
* `users.json`

### Running the Server
Starts a server at `http://localhost:3000` by default, running
as many instances as you have available processor cores:

```
pub run mpp:prod
```

To see options, i.e. port, etc.:

```
pub run mpp:prod -h
```

### Creating Users
```
pub run mpp auth -u foo -p bar
```

### Hosting a Package
```
pub run mpp mirror -n <package_name> -u <git url>
```

## Deployment
Deployment is very much an open-ended process, and thus won't be
covered in great detail here. In general, though, the *minimal* steps are:
* Install Dart.
* Install `mpp`.
* Using the `mpp` command line, create as many user accounts as is necessary.
* Using the `mpp` command line, mark repositories to be mirrored.
* Run `pub run mpp:prod`.

However, you might also consider:
* Configuring HTTPS
* Using a reverse proxy
* Running as a daemon (i.e., using `systemd`)