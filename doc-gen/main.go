package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"regexp"
	"strings"

	"gopkg.in/yaml.v2"
)

const (
	apiVersionTag     = "@apiVersion"
	nameTag           = "@name"
	descriptionTag    = "@description"
	paramTag          = "@param"
	prototypeDirName  = "prototypes"
	schemaFileName    = "mixin"
	readmeFileName    = "README.md"
)

type paramInfo struct {
	name        string
	paramType   string
	description string
}

type prototypeInfo struct {
	name        string
	description string
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
	Prototype     string            `json:"prototype" yaml:"prototype"`
	ComponentName string            `json:"componentName" yaml:"componentName"`
	Comment       string            `json:"comment" yaml:"comment"`
	Flags         map[string]string `json:"flags" yaml:"flags"`
}

type ContributorSchema struct {
	Name  string `json:"name" yaml:"name"`
	Email string `json:"email" yaml:"email"`
}

type RepositorySchema struct {
	Type string
	URL  string
}

type BugsSchema struct {
	URL string
}

type MixinSchema struct {
	Name         string               `json:"name" yaml:"name"`
	Version      string               `json:"version" yaml:"version"`
	Link         string               `json:"link" yaml:"link"`
	Output       string               `json: "output" yaml: "output"`
	Description  string               `json:"description" yaml:"description"`
	Author       string               `json:"author" yaml:"author"`
	Contributors []*ContributorSchema `json:"contributors" yaml:"contributors"`
	Repository   *RepositorySchema    `json:"repository" yaml:"repository"`
	Bugs         *BugsSchema          `json:"bugs" yaml:"bugs"`
	Keywords     []string             `json:"keywords" yaml:"keywords"`
	QuickStart   *QuickStartSchema    `json:"quickStart" yaml:"quickStart"`
	License      string               `json:"license" yaml:"license"`
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
			openText.WriteString(" " + strings.TrimSpace(line))
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
		case apiVersionTag, nameTag, descriptionTag, paramTag: // Do nothing.
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

func emitReadme(readmeFilePath string, schema *MixinSchema, prototypes []*prototypeInfo) {
	_, err := os.Stat(readmeFilePath)
	if (err != nil && !os.IsNotExist(err)) {
		panic(err)
	} else if (err == nil) {
		os.Remove(readmeFilePath)
	}
	f, err := os.OpenFile(readmeFilePath, os.O_RDWR|os.O_CREATE, 0644)
	if (err != nil) {
		panic(err)
	}
	defer f.Close()

	fmt.Fprintf(f, "# %s\n", schema.Name)
	fmt.Fprintln(f)
	fmt.Fprintf(f,
		"> This library helps you deploy [%s](%s) to your cluster.\n",
		schema.Output,
		schema.Link)
	fmt.Fprintf(f, "%s\n", schema.Description)
	fmt.Fprintln(f)
	fmt.Fprintln(f, "* [Quickstart](#quickstart)")
	fmt.Fprintln(f, "* [Prototype Reference](#prototype-reference)")

	// TODO: Sort by name.
	for _, proto := range prototypes {
		fmt.Fprintf(f, "  * [%s](#%s)\n", proto.name, proto.name)
	}

	fmt.Fprintln(f)
	fmt.Fprintf(f, "Specifically, the *%s* library files provide:\n", schema.Name)
	fmt.Fprintf(f, "* A set of relevant **parts** (_e.g._, deployments, services, secrets, and so on) that can be combined to configure %s for a wide variety of scenarios.\n", schema.Output)
	fmt.Fprintln(f)
	fmt.Fprintf(f, "* A set of **prototypes**, which are pre-fabricated \"flavors\" (or \"distributions\") of *%s*, each configured for a different use case. By passing in certain parameters, users can interactively customize these prototypes for their specific needs.\n", schema.Name)
	fmt.Fprintln(f)
	fmt.Fprintln(f, "## Quickstart")
	fmt.Fprintln(f)

	fmt.Fprintf(f,
		"*Using the [`%s`](%s) prototype, the following commands generate the Kubernetes YAML for %s, and then deploys it to your Kubernetes cluster.*\n",
		schema.QuickStart.Prototype,
		schema.QuickStart.Prototype,
		schema.Output)
	fmt.Fprintln(f)
	fmt.Fprintln(f, "1. First, create a cluster and install the ksonnet CLI (see root-level [README.md](rootReadme)).")
	fmt.Fprintln(f)
	fmt.Fprintln(f, "2. If you haven't yet created a [ksonnet application](linkToSomewhere), do so using `ks init <app-name>`.")
	fmt.Fprintln(f)
	fmt.Fprintln(f, "3. Finally, in the ksonnet application directory, run the following:")
	fmt.Fprintln(f)
	fmt.Fprintln(f, "```shell")
	fmt.Fprintln(f, "# Expand prototype as a Jsonnet file, place in a file in the")
	fmt.Fprintln(f, "# `components/` directory. (YAML and JSON are also available.)")
	fmt.Fprintf(f, "$ ks prototype use %s %s \\\n", schema.QuickStart.Prototype, schema.QuickStart.ComponentName)

	// TODO: Sort by name.
	numFlags := len(schema.QuickStart.Flags)
	i := 0
	for name, value := range schema.QuickStart.Flags {
		if i == numFlags-1 {
			fmt.Fprintf(f, "  --%s %s\n", name, value)
		} else {
			fmt.Fprintf(f, "  --%s %s \\\n", name, value)
		}
		i++
	}

	fmt.Fprintln(f)
	fmt.Fprintf(f, "# Apply to server.\n")
	fmt.Fprintf(f, "$ ks apply -f %s.jsonnet\n", schema.QuickStart.ComponentName)
	fmt.Fprintln(f, "```")
	fmt.Fprintln(f)

	fmt.Fprintln(f, "## Prototype Reference")
	fmt.Fprintln(f)
	fmt.Fprintln(f, "The set of available prototypes are enumerated below.")
	fmt.Fprintln(f)

	// TODO: Sort by name.
	for _, proto := range prototypes {
		fmt.Fprintf(f, "  * [%s](#%s)\n", proto.name, proto.name)
	}
	fmt.Fprintln(f)

	for _, proto := range prototypes {
		fmt.Fprintf(f, "### %s\n", proto.name)
		fmt.Fprintln(f)
		fmt.Fprintf(f, "When generated and applied, this prototype %s\n", proto.description)
		fmt.Fprintln(f)

		fmt.Fprintf(f, "#### Example\n")
		fmt.Fprintln(f)
		fmt.Fprintln(f, "```shell")
		fmt.Fprintln(f, "# Expand prototype as a Jsonnet file, place in a file in the")
		fmt.Fprintln(f, "# `components/` directory. (YAML and JSON are also available.)")
		fmt.Fprintf(f, "$ ks prototype use %s %s \\\n", proto.name, schema.QuickStart.ComponentName)

		// TODO: Sort by name.
		numFlags := len(proto.params)
		i := 0
		for _, param := range proto.params {
			if i == numFlags-1 {
				fmt.Fprintf(f, "  --%s %s\n", param.name, "YOUR_"+strings.ToUpper(param.name)+"_HERE")
			} else {
				fmt.Fprintf(f, "  --%s %s \\\n", param.name, "YOUR_"+strings.ToUpper(param.name)+"_HERE")
			}
			i++
		}

		fmt.Fprintln(f, "```")
		fmt.Fprintln(f)
		fmt.Fprintln(f, "Below is the Jsonnet file generated by this command.")
		fmt.Fprintln(f)

		fmt.Fprintln(f, "```")
		fmt.Fprintf(f, "// %s.jsonnet\n", schema.QuickStart.ComponentName)
		fmt.Fprintln(f, "<JSONNET HERE>")
		fmt.Fprintln(f, "```")

		fmt.Fprintln(f)
		fmt.Fprintln(f, "#### Parameters")
		fmt.Fprintln(f)
		fmt.Fprintln(f, "The available options to pass to the prototype are:")
		fmt.Fprintln(f)

		fmt.Fprintf(f, "| Name | Type | Description|\n")
		fmt.Fprintf(f, "| --- | --- | --- |\n")
		for _, param := range proto.params {
			fmt.Fprintf(f, "| `--%s` | *%s* | %s |\n", param.name, param.paramType, param.description)
		}
	}

	fmt.Fprintln(f)
	fmt.Fprintln(f)
	fmt.Fprintln(f, "[rootReadme]: https://github.com/ksonnet/mixins")
}

func getLibPrototypes(libPath string) ([]*prototypeInfo) {
	protos := []*prototypeInfo{}
	prototypeDirPath := path.Join(libPath, prototypeDirName)
	_, err := os.Stat(prototypeDirPath)
	if (err != nil && !os.IsNotExist(err)) {
		panic(err)
	} else if (err == nil) {
		prototypeFiles, err := ioutil.ReadDir(prototypeDirPath)
		if err != nil {
	    panic(err)
	  }

		for _, f := range prototypeFiles {
			jsonnetExtRegex, _ := regexp.Compile(".+\\.jsonnet$")
			if (jsonnetExtRegex.Match([]byte(f.Name()))) {
				filePath := path.Join(prototypeDirPath, f.Name())
				protoData, err := ioutil.ReadFile(filePath)
				if err != nil {
					panic(err)
				}

				proto, err := parsePrototype(string(protoData))
				if err != nil {
					panic(err)
				}

				protos = append(protos, proto)
			}
		}
	}
	return protos
}

func unmarshalSchemaData(libPath string, mixin *MixinSchema) {
	jsonSchemaPath := path.Join(libPath, fmt.Sprintf("%s.json", schemaFileName))
	schemaData, err := ioutil.ReadFile(jsonSchemaPath)
	if (err == nil) {
		if err = json.Unmarshal(schemaData, &mixin); err != nil {
			panic(err)
		} else {
			return
		}
	}

	yamlSchemaPath := path.Join(libPath, fmt.Sprintf("%s.yaml", schemaFileName))
	schemaData, err = ioutil.ReadFile(yamlSchemaPath)
	if (err == nil) {
		if err = yaml.Unmarshal(schemaData, &mixin); err != nil {
			panic(err)
		} else {
			return
		}
	}

	panic(err)
}

func main() {
	libPath := os.Args[1]
	mixin := MixinSchema{}
	unmarshalSchemaData(libPath, &mixin)

	protos := getLibPrototypes(libPath)


	readmeFilePath := path.Join(libPath, readmeFileName)
	emitReadme(readmeFilePath, &mixin, protos)
}
