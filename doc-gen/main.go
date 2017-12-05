package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

const (
	apiVersionTag  = "@apiVersion"
	nameTag        = "@name"
	descriptionTag = "@description"
	shortDescriptionTag = "@shortDescription"
	paramTag       = "@param"
	optionalParamTag = "@optionalParam"
)

type paramInfo struct {
	name        string
	paramType   string
	description string
}

type prototypeInfo struct {
	name        string
	description string
	shortDescription string
	params      []*paramInfo
}

func (pi *prototypeInfo) add(tag, text string) error {
	switch tag {
	case apiVersionTag:
	case nameTag:
		if pi.name != "" {
			return fmt.Errorf("Prototype heading comment has two '@name' fields")
		}
		pi.name = text
	case descriptionTag:
		if pi.description != "" {
			return fmt.Errorf("Prototype heading comment has two '@description' fields")
		}
		pi.description = text
	case shortDescriptionTag:
		if pi.shortDescription != "" {
			return fmt.Errorf("Prototype heading comment has two '@shortDescription' fields")
		}
		pi.shortDescription = text
	case paramTag:
		// NOTE: There is usually more than one `@param`, so we don't
		// check length here.

		split := strings.SplitN(text, " ", 3)
		if len(split) < 3 {
			return fmt.Errorf("Param fields must have '<name> <type> <description>, but got:\n%s", text)
		}

		switch split[1] {
		case "number", "string", "number-or-string": // Do nothing.
		default:
			return fmt.Errorf("Param type must be 'number', 'string', or 'number-or-string', but got '%s'", split[1])
		}

		pi.params = append(pi.params, &paramInfo{
			name:        split[0],
			paramType:   split[1],
			description: split[2],
		})
	case optionalParamTag:
		return nil
	default:
		return fmt.Errorf(`Line in prototype heading comment is formatted incorrectly; '%s' is not
recognized as a tag. Only tags can begin lines, and text that is wrapped must
be indented. For example:

// @description This is a long description
//   that we are wrapping on two lines`, tag)
	}

	return nil
}

type QuickStartSchema struct {
	Prototype     string            `json:"prototype"`
	ComponentName string            `json:"componentName"`
	Comment       string            `json:"comment"`
	Flags         map[string]string `json:"flags"`
}

type ContributorSchema struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}

type RepositorySchema struct {
	Type string
	URL  string
}

type BugsSchema struct {
	URL string
}

type MixinSchema struct {
	Name         string               `json:"name"`
	Version      string               `json:"version"`
	Description  string               `json:"description"`
	Author       string               `json:"author"`
	Contributors []*ContributorSchema `json:"contributors"`
	Repository   *RepositorySchema    `json:"repository"`
	Bugs         *BugsSchema          `json:"bugs"`
	Keywords     []string             `json:"keywords"`
	QuickStart   *QuickStartSchema    `json:"quickStart"`
	License      string               `json:"license"`
}

func parsePrototype(data string) (*prototypeInfo, error) {
	// Get comment block at the top of the file.
	seenCommentLine := false
	commentBlock := []string{}
	for _, line := range strings.Split(data, "\n") {
		const commentPrefix = "// "
		line = strings.TrimSpace(line)

		// Skip blank lines
		if line == "" && !seenCommentLine {
			continue
		}

		if !strings.HasPrefix(line, "//") {
			break
		}

		seenCommentLine = true

		// Reject comments formatted like this, with no space between '//'
		// and the first word:
		//
		//   //Foo
		//
		// But not the empty comment line:
		//
		//   //
		//
		// Also, trim any leading space between the '//' characters and
		// the first word, and place that in `commentBlock`.
		if !strings.HasPrefix(line, commentPrefix) {
			if len(line) > 3 {
				return nil, fmt.Errorf("Prototype heading comments are required to have a space after the '//' that begins the line")
			}
			commentBlock = append(commentBlock, strings.TrimPrefix(line, "//"))
		} else {
			commentBlock = append(commentBlock, strings.TrimPrefix(line, commentPrefix))
		}
	}

	// Parse the prototypeInfo from the heading comment block.
	pinfo := prototypeInfo{}
	firstPass := true
	openTag := ""
	var openText bytes.Buffer
	for _, line := range commentBlock {
		split := strings.SplitN(line, " ", 2)
		if len(split) < 1 {
			continue
		}

		if len(line) == 0 || strings.HasPrefix(line, " ") {
			if openTag == "" {
				return nil, fmt.Errorf("Free text is not allowed in heading comment of prototype spec, all text must be in a field. The line of the error:\n'%s'", line)
			}
			openText.WriteString(strings.TrimSpace(line) + "\n")
			continue
		} else if len(split) < 2 {
			return nil, fmt.Errorf("Invalid field '%s', fields must have a non-whitespace value", line)
		}

		if err := pinfo.add(openTag, openText.String()); !firstPass && err != nil {
			return nil, err
		}
		openTag = split[0]
		openText = bytes.Buffer{}
		openText.WriteString(strings.TrimSpace(split[1]))
		switch split[0] {
		case apiVersionTag, nameTag, descriptionTag, shortDescriptionTag, optionalParamTag, paramTag: // Do nothing.
		default:
			return nil, fmt.Errorf(`Line in prototype heading comment is formatted incorrectly; '%s' is not
recognized as a tag. Only tags can begin lines, and text that is wrapped must
be indented. For example:

  // @description This is a long description
  //   that we are wrapping on two lines`, split[0])
		}

		firstPass = false
	}

	if err := pinfo.add(openTag, openText.String()); !firstPass && err != nil {
		return nil, err
	}

	if pinfo.name == "" || pinfo.description == "" {
		return nil, fmt.Errorf("Invalid prototype specification, all fields are required. Object:\n%s", pinfo)
	}

	return &pinfo, nil
}

func emitReadme(schema *MixinSchema, prototypes []*prototypeInfo) {
	fmt.Printf("# %s\n", schema.Name)
	fmt.Println()
	fmt.Printf("> %s\n", schema.Description)
	fmt.Println()
	fmt.Println("* [Quickstart](#quickstart)")
	fmt.Println("* [Using Prototypes](#using-prototypes)")

	// TODO: Sort by name.
	for _, proto := range prototypes {
		fmt.Printf("  * [%s](#%s)\n", proto.name, proto.name)
	}

	fmt.Println()
	fmt.Println("## Quickstart")
	fmt.Println()

	fmt.Printf("*The following commands use the `%s` prototype to generate Kubernetes YAML for %s, and then deploys it to your Kubernetes cluster.*\n", schema.QuickStart.Prototype, schema.Name)
	fmt.Println()
	fmt.Println("First, create a cluster and install the ksonnet CLI (see root-level [README.md](rootReadme)).")
	fmt.Println()
	fmt.Println("If you haven't yet created a [ksonnet application](linkToSomewhere), do so using `ks init <app-name>`.")
	fmt.Println()
	fmt.Println("Finally, in the ksonnet application directory, run the following:")
	fmt.Println()
	fmt.Println("```shell")
	fmt.Println("# Expand prototype as a Jsonnet file, place in a file in the")
	fmt.Println("# `components/` directory. (YAML and JSON are also available.)")
	fmt.Printf("$ ks prototype use %s %s \\\n", schema.QuickStart.Prototype, schema.QuickStart.ComponentName)

	// TODO: Sort by name.
	numFlags := len(schema.QuickStart.Flags)
	i := 0
	for name, value := range schema.QuickStart.Flags {
		if i == numFlags-1 {
			fmt.Printf("  --%s %s\n", name, value)
		} else {
			fmt.Printf("  --%s %s \\\n", name, value)
		}
		i++
	}

	fmt.Println()
	fmt.Printf("# Apply to server.\n")
	fmt.Printf("$ ks apply -f %s.jsonnet\n", schema.QuickStart.ComponentName)
	fmt.Println("```")
	fmt.Println()

	fmt.Println("## Using the library")
	fmt.Println()
	fmt.Printf("The library files for %s define a set of relevant *parts* (_e.g._, deployments, services, secrets, and so on) that can be combined to configure %s for a wide variety of scenarios. For example, a database like Redis may need a secret to hold the user password, or it may have no password if it's acting as a cache.\n", schema.Name, schema.Name)
	fmt.Println()
	fmt.Printf("This library provides a set of pre-fabricated \"flavors\" (or \"distributions\") of %s, each of which is configured for a different use case. These are captured as ksonnet *prototypes*, which allow users to interactively customize these distributions for their specific needs.\n", schema.Name)
	fmt.Println()
	fmt.Println("These prototypes, as well as how to use them, are enumerated below.")
	fmt.Println()

	for _, proto := range prototypes {
		fmt.Printf("### %s\n", proto.name)
		fmt.Println()
		fmt.Printf(proto.description)
		fmt.Println()

		fmt.Printf("#### Example\n")
		fmt.Println()
		fmt.Println("```shell")
		fmt.Println("# Expand prototype as a Jsonnet file, place in a file in the")
		fmt.Println("# `components/` directory. (YAML and JSON are also available.)")
		fmt.Printf("$ ks prototype use %s %s \\\n", proto.name, schema.QuickStart.ComponentName)

		// TODO: Sort by name.
		numFlags := len(proto.params)
		i := 0
		for _, param := range proto.params {
			if i == numFlags-1 {
				fmt.Printf("  --%s %s\n", param.name, "YOUR_"+strings.ToUpper(param.name)+"_HERE")
			} else {
				fmt.Printf("  --%s %s \\\n", param.name, "YOUR_"+strings.ToUpper(param.name)+"_HERE")
			}
			i++
		}

		fmt.Println("```")
		// fmt.Println()
		// fmt.Println("Below is the Jsonnet file generated by this command.")
		// fmt.Println()
    //
		// fmt.Println("```")
		// fmt.Printf("// %s.jsonnet\n", schema.QuickStart.ComponentName)
		// fmt.Println("<JSONNET HERE>")
		// fmt.Println("```")

		fmt.Println()
		fmt.Println("#### Parameters")
		fmt.Println()
		fmt.Println("The available options to pass prototype are:")
		fmt.Println()

		for _, param := range proto.params {
			fmt.Printf("* `--%s=<%s>`: %s [%s]\n", param.name, param.name, param.description, param.paramType)
		}
	}

	fmt.Println()
	fmt.Println()
	fmt.Println("[rootReadme]: https://github.com/ksonnet/mixins")
}

func main() {
	schemaData, err := ioutil.ReadFile(os.Args[1])
	if err != nil {
		panic(err)
	}

	protos := []*prototypeInfo{}
	for _, arg := range os.Args[2:] {
		protoData, err := ioutil.ReadFile(arg)
		if err != nil {
			panic(err)
		}

		proto, err := parsePrototype(string(protoData))
		if err != nil {
			panic(err)
		}

		protos = append(protos, proto)
	}

	mixin := MixinSchema{}
	if err := json.Unmarshal(schemaData, &mixin); err != nil {
		panic(err)
	}

	emitReadme(&mixin, protos)
}
