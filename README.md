# ksonnet Mixins

## Overview

This repository contains a collection of [ksonnet][1] libraries,
designed to make it easy to:

* *Embed other projects* into your Kubernetes applications as "sidecars"
  (_e.g._, adding the [Honeycomb observability agent][7] to an existing
  `Deployment` you've authored).
* *Customize and extend Kubernetes applications* to fit your needs
  (_i.e._, with ksonnet, you can manipulate Kubernetes
  API objects, so you are not constrained by a single YAML values
  file.)

For more information, see the [ksonnet Github repo][2].

## Repository structure

The repository is structured into two main sets of libraries:

* `incubator/`, which contains libraries that are relatively new, and still need to be vetted by the community (similar to alpha/beta releases).
* `stable/`, which contains libraries that are considered to be
  production-ready.

As the project matures, we expect most projects to transition to
`stable/`.

## Contributing

Thanks for taking the time to join our community and start
contributing!

### Before you start

* Please familiarize yourself with the [Code of Conduct][3] before
  contributing.
* See [CONTRIBUTING.md][4] for instructions on the developer
  certificate of origin that we require.

### Pull requests

* We welcome pull requests. Feel free to dig through the [issues][5]
  and jump in.

## Contact us

See the [contact information for the ksonnet community][6].

[1]: http://ksonnet.heptio.com/
[2]: https://github.com/ksonnet/ksonnet-lib
[3]: https://github.com/ksonnet/ksonnet-lib/blob/master/CODE-OF-CONDUCT.md
[4]: https://github.com/ksonnet/ksonnet-lib/blob/master/CONTRIBUTING.md
[5]: https://github.com/ksonnet/mixins/issues
[6]: https://github.com/ksonnet/ksonnet-lib/blob/master/README.md#contact-us
[7]: https://github.com/ksonnet/mixins/tree/honeycomb/incubator/honeycomb-agent
