# ksonnet Libraries

## Overview

This repository contains [ksonnet][1] libraries, which are designed to make it
easy to embed common Kubernetes configurations into your own applications.

It is structured as follows:

* `incubator/`, a ksonnet [registry][2] that can be used with the CLI tool, `ks`. For more info, see the [incubator README][7].

* `deprecated/`, which contains ksonnet libraries that are no longer supported

In the future, as the project matures, we expect most libraries in `incubator/`
to transition to a new `stable/` directory.

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

[1]: https://ksonnet.io
[2]: https://ksonnet.io/docs/concepts#registry
[3]: /CODE-OF-CONDUCT.md
[4]: /CONTRIBUTING.md
[5]: https://github.com/ksonnet/mixins/issues
[6]: https://github.com/ksonnet/ksonnet#contributing
[7]: /incubator/README.md
