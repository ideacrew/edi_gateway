module Policies
  class CommandHandler < Sequent::CommandHandler
    on ::Policies::Commands::CreatePolicy do |command|
      repository.add_aggregate ::Policies::Policy.new(command)
    end
  end
end