
module ZMQ

  class Context
    include ZMQ::Util

    attr_reader :context, :pointer

    # Recommended to use the default for +io_threads+
    # since most programs will not saturate I/O. 
    #
    # The rule of thumb is to make +io_threads+ equal to the number 
    # gigabits per second that the application will produce.
    #
    # The +io_threads+ number specifies the size of the thread pool
    # allocated by 0mq for processing incoming/outgoing messages.
    #
    # Returns a context object. It's necessary for passing to the
    # #Socket constructor when allocating new sockets. All sockets
    # live within a context. Sockets in one context may not be accessed
    # from another context; doing so raises an exception.
    #
    # Also, Sockets should *only* be accessed from the thread where they
    # were first created. Do *not* pass sockets between threads; pass
    # in the context and allocate a new socket per thread.
    #
    # To connect sockets between contexts, use +inproc+ or +ipc+
    # transport and set up a 0mq socket between them. This is also the
    # recommended technique for allowing sockets to communicate between
    # threads.
    #
    # Will raise a #ContextError when the native library context cannot be
    # be allocated.
    #
    def initialize io_threads = 1
      @sockets = []
      @context = LibZMQ.zmq_init io_threads
      @pointer = @context
      error_check 'zmq_init', (@context.nil? || @context.null?) ? -1 : 0

      define_finalizer
    end

    # Call to release the context and any remaining data associated
    # with past sockets. This will close any sockets that remain
    # open; further calls to those sockets will return -1 to indicate
    # the operation failed.
    #
    # Returns 0 for success, -1 for failure.
    #
    def terminate
      unless @context.nil? || @context.null?
        rc = LibZMQ.zmq_term @context
        @context = nil
        @sockets = nil
        remove_finalizer
        rc
      else
        0
      end
    end

    # Short-cut to allocate a socket for a specific context.
    #
    # Takes several +type+ values:
    #   #ZMQ::REQ
    #   #ZMQ::REP
    #   #ZMQ::PUB
    #   #ZMQ::SUB
    #   #ZMQ::PAIR
    #   #ZMQ::PULL
    #   #ZMQ::PUSH
    #   #ZMQ::DEALER
    #   #ZMQ::ROUTER
    #
    # Returns a #ZMQ::Socket.
    #
    # May raise a #ContextError if the socket allocation fails.
    #
    def socket type
      Socket.new @context, type
    end


    private

    def define_finalizer
      ObjectSpace.define_finalizer(self, self.class.close(@context))
    end

    def remove_finalizer
      ObjectSpace.undefine_finalizer self
    end

    def self.close context
      Proc.new { LibZMQ.zmq_term context unless context.null? }
    end
  end

end # module ZMQ
