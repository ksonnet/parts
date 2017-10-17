# mixins/doc-gen

The script in this repo is used to auto-generate README documentation for the [mixins in incubator/](../incubator).

## Usage

```
go run main.go [PATH-TO-MIXIN-LIB]
```
This command assumes that the mixin library at `[PATH-TO-MIXIN-LIB]` has the following subdirectories/files:

* `mixin.yaml` OR `mixin.json`: A file with metadata about the mixin library.

* `prototypes/`: Contains `*.jsonnet` files that defines the library's prototypes.

**Note that this command overwrites the existing README at the mixin library's root.**

## Example

```
# Run from the root of the repository (mixins/)
$ go run ./doc-gen/main.go ./incubator/nginx/
```
