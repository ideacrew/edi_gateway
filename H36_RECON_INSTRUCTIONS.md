## Recon Instructions

You can run a preliminary recon against the H36 by:
1. Create a directory in the app root called `h36_files`
2. Put all your H36 xml files into the `h36_files` directory, directly.  All files need to be directly under the `h36_files` directory with no intermediate directories in between.
3. Run `bundle exec rails recon:h36_files` - this will run the rake task.  It is crucial that edi_gateway has access to an instance of the GlueDB database that is what you expect to be checking against (preferably the same database that generated your H36s).
4. The IRS Group <-> Policy mapping should now exist in a file called `irs_group_policy_mappings.csv`
5. The list of outstanding policies not present in the H36 files is in a file called `policies_not_in_h36.csv`