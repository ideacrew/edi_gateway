VIEW_SCHEMA_VERSION = 1
  
class SequentMigrations < Sequent::Migrations::Projectors
 def self.version
   VIEW_SCHEMA_VERSION
 end
  
 def self.versions
   {
     '1' => [
      Policies::Projector,
      Invoices::Projector
     ],
   }
 end
end
