module Policies
  class CommandHandler < Sequent::CommandHandler
    on ::Policies::Commands::CreatePolicy do |command|
      repository.add_aggregate ::Policies::Policy.new(command)
    end

    on ::Policies::Commands::AddSpan do |command|
      do_with_aggregate(command, ::Policies::Policy) do |policy|
        policy.add_span(command)
      end
    end
  end
end