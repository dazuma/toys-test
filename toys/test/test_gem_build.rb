# frozen_string_literal: true

# Copyright 2019 Daniel Azuma
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
;

require "helper"
require "toys/utils/exec"

describe "gem_build template" do
  let(:template_lookup) { Toys::ModuleLookup.new.add_path("toys/templates") }
  let(:toys_dir) { File.dirname(__dir__) }

  describe "unit functionality" do
    let(:template) { template_lookup.lookup(:gem_build).new }

    it "handles the name field" do
      assert_equal("build", template.name)
      template.name = "hi"
      assert_equal("hi", template.name)
      template.name = nil
      assert_equal("build", template.name)
    end

    it "handles the gem_name field" do
      assert_equal("toys", template.gem_name)
      template.gem_name = "toys-core"
      assert_equal("toys-core", template.gem_name)
      template.gem_name = nil
      assert_equal("toys", template.gem_name)
    end

    it "handles the output_flags field" do
      assert_equal([], template.output_flags)
      template.output_flags = "--out"
      assert_equal(["--out"], template.output_flags)
      template.output_flags = ["--out", "-o"]
      assert_equal(["--out", "-o"], template.output_flags)
      template.output_flags = true
      assert_equal(["-o", "--output"], template.output_flags)
      template.output_flags = nil
      assert_equal([], template.output_flags)
    end

    it "handles the push_tag field" do
      assert_equal(false, template.push_tag)
      template.push_tag = "upstream"
      assert_equal("upstream", template.push_tag)
      template.push_tag = true
      assert_equal("origin", template.push_tag)
      template.push_tag = false
      assert_equal(false, template.push_tag)
    end

    it "handles the task_names field" do
      assert_equal("Build", template.task_names)
      template.install_gem = true
      assert_equal("Install", template.task_names)
      template.push_gem = true
      assert_equal("Install and Release", template.task_names)
      template.install_gem = false
      assert_equal("Release", template.task_names)
      template.push_gem = false
      assert_equal("Build", template.task_names)
    end
  end

  describe "integration functionality" do
    let(:cli) { Toys::CLI.new(middleware_stack: [], template_lookup: template_lookup) }
    let(:loader) { cli.loader }

    it "builds toys into tmp directory" do
      loader.add_block do
        expand :gem_build, output: "tmp/toys.gem"
      end
      Dir.chdir(toys_dir) do
        FileUtils.rm_rf("tmp")
        FileUtils.mkdir_p("tmp")
        out, _err = capture_subprocess_io do
          assert_equal(0, cli.run("build"))
        end
        assert_match(/Successfully built RubyGem/, out)
        assert(File.file?("tmp/toys.gem"))
        FileUtils.rm_rf("tmp")
      end
    end

    it "supports default output flags" do
      loader.add_block do
        expand :gem_build, output_flags: true
      end
      Dir.chdir(toys_dir) do
        FileUtils.rm_rf("tmp")
        FileUtils.mkdir_p("tmp")
        out, _err = capture_subprocess_io do
          assert_equal(0, cli.run("build", "-o", "tmp/toys.gem"))
        end
        assert_match(/Successfully built RubyGem/, out)
        assert(File.file?("tmp/toys.gem"))
        FileUtils.rm_rf("tmp")
      end
    end

    it "supports custom output flags" do
      loader.add_block do
        expand :gem_build, output_flags: ["--outfile"]
      end
      Dir.chdir(toys_dir) do
        FileUtils.rm_rf("tmp")
        FileUtils.mkdir_p("tmp")
        out, _err = capture_subprocess_io do
          assert_equal(0, cli.run("build", "--outfile", "tmp/toys.gem"))
        end
        assert_match(/Successfully built RubyGem/, out)
        assert(File.file?("tmp/toys.gem"))
        FileUtils.rm_rf("tmp")
      end
    end
  end
end
