module Feedjira

  module Parser
    class PodcastItemEnclosure

      include SAXMachine

      attribute :url
      attribute :length
      attribute :type

    end
  end

end
