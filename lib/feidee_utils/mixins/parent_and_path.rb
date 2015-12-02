module FeideeUtils
  module Mixins
    # Requires:
    #   instance methods: poid, parent_poid, raw_path
    #   class methods: find_by_id
    module ParentAndPath
      NullPOID = 0

      class InconsistentDepthException < Exception
      end

      class InconsistentPathException < Exception
      end

      def validate_depth_integrity
        path_depth = path.length - 1
        if path_depth != depth
          raise InconsistentDepthException,
            "Path is #{path}, but the given depth is #{depth}.\n" +
            inspect
        end
      end

      def validate_one_level_path_integrity
        path_array = path.clone
        last_poid = path_array.pop

        if last_poid != poid
          raise InconsistentPathException,
            "The last node in path is #{last_poid}, but the current poid is #{poid}.\n" +
            inspect
        end

        if has_parent? and path_array != parent.path
          raise InconsistentPathException,
            "Path is #{path}, but path of parent is #{parent.path}.\n" +
            inspect
        end
      end

      def validate_path_integrity_hard
        cur = self
        step = 0
        while cur or step != path.length
          step += 1
          poid = path[-step]
          if !cur or poid == nil or poid != cur.poid
            raise InconsistentPathException,
              "Reverse path and trace are different at step #{step}. " +
              "Path shows #{poid}, but trace shows #{cur and cur.poid}.\n" +
              inspect
          end

          cur = cur.has_parent? && cur.parent
        end
      end

      def path
        @path ||= (raw_path.split("/").map do |poid| poid.to_i end)[1..-1]
      end

      def parent
        self.class.find_by_id(parent_poid)
      end

      def has_parent?
        parent_poid != NullPOID
      end
    end
  end
end
