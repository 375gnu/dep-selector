require File.expand_path(File.join(File.dirname(__FILE__), '..','spec_helper'))

simple_cookbook_version_constraint =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{}},
  ]

simple_cookbook_version_constraint_2 =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0", "C"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{}},
   {"key"=>["C", "2.0.0"], "value"=>{}},
   {"key"=>["C", "3.0.0"], "value"=>{}}
  ]

simple_cookbook_version_constraint_3 =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>">= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
  ]

moderate_cookbook_version_constraint =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0", "C"=>">= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{"D"=>">= 1.0.0"}},
   {"key"=>["C", "2.0.0"], "value"=>{"D"=>">= 2.0.0"}},
   {"key"=>["C", "3.0.0"], "value"=>{"D"=>">= 3.0.0"}},
   {"key"=>["C", "4.0.0"], "value"=>{"D"=>">= 4.0.0"}},
   {"key"=>["D", "1.0.0"], "value"=>{}},
   {"key"=>["D", "2.0.0"], "value"=>{}},
   {"key"=>["D", "3.0.0"], "value"=>{}},
   {"key"=>["D", "4.0.0"], "value"=>{}} 
  ]

moderate_cookbook_version_constraint_2 =
  [{"key"=>["A", "1.0"], "value"=>{"C"=>"< 4.0"}},
   {"key"=>["B", "1.0"], "value"=>{"C"=>"< 3.0"}},
   {"key"=>["C", "2.0"], "value"=>{"D"=>"> 1.0", "F"=>">= 0.0.0"}},
   {"key"=>["C", "3.0"], "value"=>{"D"=>"> 2.0", "E"=>">= 0.0.0"}},
   {"key"=>["D", "1.1"], "value"=>{}},
   {"key"=>["D", "2.1"], "value"=>{}},
   {"key"=>["E", "1.0"], "value"=>{}},
   {"key"=>["F", "1.0"], "value"=>{}},
  ]

padding_packages =
  [{"key"=>["padding1", "1.0"], "value"=>{}},
   {"key"=>["padding2", "1.0"], "value"=>{}}
  ]

dependencies_whose_constraints_match_no_versions =
  [{"key"=>["A", "1.0"], "value"=>{}},
   {"key"=>["B", "1.0"], "value"=>{"A"=>"> 1.0"}},
   {"key"=>["C", "1.0"], "value"=>{"B"=>nil}},
   *padding_packages
  ]

dependency_on_non_existent_package =
  [{"key"=>["depends_on_nosuch", "1.0.0"], "value"=>{"nosuch"=>"= 2.0.0"}},
   {"key"=>["transitive_dep_on_nosuch", "1.0.0"], "value"=>{"depends_on_nosuch"=>nil}},
   *padding_packages
  ]

satisfiable_circular_dependency_graph =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{"A"=>"= 1.0.0"}}
  ]

unsatisfiable_circular_dependency_graph =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 1.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 2.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{"A"=>"= 2.0.0"}},
   {"key"=>["B", "2.0.0"], "value"=>{"A"=>"= 1.0.0"}},
   *padding_packages
  ]

def compute_edit_distance(soln, current_versions)
  current_versions.inject(0) do |acc, curr_version|
    # TODO [cw,2010/11/21]: This edit distance only increases when a
    # package that is currently deployed is changed, not when a new
    # dependency is added. I think there is an argument to be made
    # that also including new packages is worthy of an edit distance
    # bump, since the interpretation can be that any difference in
    # code that is run (not just changing existing code) could be
    # considered "infrastructure instability". And by that same
    # reasoning, perhaps removal of packages should increase the edit
    # distance, as well. This needs to be considered.
    pkg_name, curr_version = curr_version
    if soln.has_key?(pkg_name)
      putative_version = soln[pkg_name]
#      puts "Package #{pkg_name}: current = #{curr_version} (#{curr_version.class}), soln assignment = #{putative_version} (#{putative_version.class})#{putative_version == curr_version ? "" : " (changing)"}"
      acc -= 1 unless putative_version == curr_version
      end
    acc
  end
end

def compute_latest_version_count(soln, latest_versions)
  latest_versions.inject(0) do |acc, version|
    pkg_name, latest_version = version
    if soln.has_key?(pkg_name) 
      trial_version = soln[pkg_name]
#      puts "Package #{pkg_name}: latest = #{latest_version} (#{latest_version.class}), soln assignment = #{trial_version} (#{trial_version.class})#{trial_version == latest_version ? "" : " (NOT latest)"}"
      acc -= 1 unless trial_version == latest_version
    end
    acc
  end
end

def create_latest_version_objective_function(dep_graph)
  # determine latest versions from dep_graph
  latest_versions = {}
  dep_graph.each_package do |pkg|
    latest_version_id =  pkg.densely_packed_versions.range.last
#    pp :name=>pkg.name, :latest_version_id=>latest_version_id, :latest_version_string=>pkg.densely_packed_versions.sorted_elements[latest_version_id]
    latest_versions[pkg.name] = pkg.densely_packed_versions.sorted_elements[latest_version_id]
  end
  
  lambda do |soln|
    compute_latest_version_count(soln, latest_versions)
  end
end

def create_minimum_churn_objective_function(dep_graph, current_versions)
  real_current_versions = current_versions.inject({}) do |acc, curr_version|
    acc[curr_version.first] = DepSelector::Version.new(curr_version.last)
    acc
  end

lambda do |soln|
    compute_edit_distance(soln, real_current_versions)
  end
end

# This method composes the latest_version and minimum_churn objective
# functions.
def create_latest_version_minimum_churn_objective_function(dep_graph, current_versions)
  latest_version_objective_function = create_latest_version_objective_function(dep_graph)
  minimum_churn_objective_function = create_minimum_churn_objective_function(dep_graph, current_versions)
  lambda do |soln|
    latest_weight = latest_version_objective_function.call(soln)
    churn_weight = minimum_churn_objective_function.call(soln)
    [latest_weight, churn_weight]    
  end
end

# Used to compare the above composite objective function
class Array
  def > (b)
    (self <=> b) > 0
  end
end

describe DepSelector::Selector do
  
  describe "solves without an objective function" do

    it "a simple set of constraints and includes transitive dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 1.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "2.0.0",
                        "B" => "1.0.0",
                        "C" => "1.0.0"
                      })
    end

    it "a simple set of constraints and doesn't include unnecessary dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 2.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "2.0.0"
                      })
    end

    it "a simple set of constraints and does not include unnecessary assignments" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 2.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "2.0.0"
                      })
    end

    it "and indicates which solution constraint makes the system unsatisfiable if there is no solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint_2)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["C", "= 3.0.0"]
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_constraint.should == unsatisfiable_solution_constraints.last
      end
    end

    it "can solve a moderately complex system with a unique solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, moderate_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["C", "= 4.0"],
                                ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "2.0.0",
                        "C" => "4.0.0",
                        "D" => "4.0.0"
                      })
    end

    it "should find a solution regardless of the dependency graph having a packages with a dependency constrained to a range that includes no packages" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 1.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "2.0.0",
                        "B" => "1.0.0",
                        "C" => "1.0.0"
                      })
    end

    it "fails to find a solution when a solution constraint is constrained to a range that includes no packages" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["A", "> 1.0"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_constraint.to_s.should == unsatisfiable_solution_constraints[1].to_s
      end
    end

    it "fails to find a solution when a solution constraint's dependency is constrained to a range that includes no packages" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["B"],
                                ["padding2"],
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_constraint.to_s.should == unsatisfiable_solution_constraints[1].to_s
      end
    end

    it "fails to find a solution when a solution constraint's transitive dependency is constrained to a range that includes no packages" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["C"],
                                ["padding2"],
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_constraint.to_s.should == unsatisfiable_solution_constraints[1].to_s
      end
    end

    it "should find a solution if one can be found regardless of invalid dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 1.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "2.0.0",
                        "B" => "1.0.0",
                        "C" => "1.0.0"
                      })
    end

    it "should fail to find a solution if a non-existent package is in the solution constraints" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["nosuch"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::InvalidPackage => nse
        nse.message.should == "nosuch does not exist in the dependency graph or has no versions"
      end
    end

    it "should fail to find a solution if a package with an invalid dependency is a direct dependency of one of the solution constraints" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["depends_on_nosuch"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_constraint.to_s.should == solution_constraints[1].to_s
      end
    end

    it "should fail to find a solution if a package with an invalid dependency is a transitive dependency of one of the solution constraints" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["transitive_dep_on_nosuch"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_constraint.to_s.should == solution_constraints[1].to_s
      end
    end

    it "should solve a circular dependency graph that has a valid solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, satisfiable_circular_dependency_graph)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "1.0.0"
                      })
    end

    it "should fail to find a solution for (and not infinitely recurse on) a dependency graph that does not have a valid solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, unsatisfiable_circular_dependency_graph)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["A", "= 1.0.0"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_constraint.to_s.should == solution_constraints[1].to_s
      end
    end

  end

  # TODO [cw,2011/2/4]: Add a test for a set of solution constraints
  # that contains multiple restrictions on the same package. Do the
  # same for a PackageVersion that has several Dependencies on the
  # same package, some satisfiable, some not.

end
