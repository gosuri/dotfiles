" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
ruby/command-t/controller.rb	[[[1
317
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/finder/buffer_finder'
require 'command-t/finder/file_finder'
require 'command-t/match_window'
require 'command-t/prompt'
require 'command-t/vim/path_utilities'

module CommandT
  class Controller
    include VIM::PathUtilities

    def initialize
      @prompt = Prompt.new
      @buffer_finder = CommandT::BufferFinder.new
      set_up_file_finder
      set_up_max_height
    end

    def show_buffer_finder
      @path          = VIM::pwd
      @active_finder = @buffer_finder
      show
    end

    def show_file_finder
      # optional parameter will be desired starting directory, or ""
      @path             = File.expand_path(::VIM::evaluate('a:arg'), VIM::pwd)
      @file_finder.path = @path
      @active_finder    = @file_finder
      show
    rescue Errno::ENOENT
      # probably a problem with the optional parameter
      @match_window.print_no_such_file_or_directory
    end

    def hide
      @match_window.close
      if VIM::Window.select @initial_window
        if @initial_buffer.number == 0
          # upstream bug: buffer number misreported as 0
          # see: https://wincent.com/issues/1617
          ::VIM::command "silent b #{@initial_buffer.name}"
        else
          ::VIM::command "silent b #{@initial_buffer.number}"
        end
      end
    end

    def flush
      set_up_max_height
      set_up_file_finder
    end

    def handle_key
      key = ::VIM::evaluate('a:arg').to_i.chr
      if @focus == @prompt
        @prompt.add! key
        list_matches
      else
        @match_window.find key
      end
    end

    def backspace
      if @focus == @prompt
        @prompt.backspace!
        list_matches
      end
    end

    def delete
      if @focus == @prompt
        @prompt.delete!
        list_matches
      end
    end

    def accept_selection options = {}
      selection = @match_window.selection
      hide
      open_selection(selection, options) unless selection.nil?
    end

    def toggle_focus
      @focus.unfocus # old focus
      @focus = @focus == @prompt ? @match_window : @prompt
      @focus.focus # new focus
    end

    def cancel
      hide
    end

    def select_next
      @match_window.select_next
    end

    def select_prev
      @match_window.select_prev
    end

    def clear
      @prompt.clear!
      list_matches
    end

    def cursor_left
      @prompt.cursor_left if @focus == @prompt
    end

    def cursor_right
      @prompt.cursor_right if @focus == @prompt
    end

    def cursor_end
      @prompt.cursor_end if @focus == @prompt
    end

    def cursor_start
      @prompt.cursor_start if @focus == @prompt
    end

    def leave
      @match_window.leave
    end

    def unload
      @match_window.unload
    end

  private

    def show
      @initial_window   = $curwin
      @initial_buffer   = $curbuf
      @match_window     = MatchWindow.new \
        :prompt               => @prompt,
        :match_window_at_top  => get_bool('g:CommandTMatchWindowAtTop'),
        :match_window_reverse => get_bool('g:CommandTMatchWindowReverse')
      @focus            = @prompt
      @prompt.focus
      register_for_key_presses
      clear # clears prompt and lists matches
    end

    def set_up_max_height
      @max_height = get_number('g:CommandTMaxHeight') || 0
    end

    def set_up_file_finder
      @file_finder = CommandT::FileFinder.new nil,
        :max_files              => get_number('g:CommandTMaxFiles'),
        :max_depth              => get_number('g:CommandTMaxDepth'),
        :always_show_dot_files  => get_bool('g:CommandTAlwaysShowDotFiles'),
        :never_show_dot_files   => get_bool('g:CommandTNeverShowDotFiles'),
        :scan_dot_directories   => get_bool('g:CommandTScanDotDirectories')
    end

    def exists? name
      ::VIM::evaluate("exists(\"#{name}\")").to_i != 0
    end

    def get_number name
      exists?(name) ? ::VIM::evaluate("#{name}").to_i : nil
    end

    def get_bool name
      exists?(name) ? ::VIM::evaluate("#{name}").to_i != 0 : nil
    end

    def get_string name
      exists?(name) ? ::VIM::evaluate("#{name}").to_s : nil
    end

    # expect a string or a list of strings
    def get_list_or_string name
      return nil unless exists?(name)
      list_or_string = ::VIM::evaluate("#{name}")
      if list_or_string.kind_of?(Array)
        list_or_string.map { |item| item.to_s }
      else
        list_or_string.to_s
      end
    end

    # Backslash-escape space, \, |, %, #, "
    def sanitize_path_string str
      # for details on escaping command-line mode arguments see: :h :
      # (that is, help on ":") in the Vim documentation.
      str.gsub(/[ \\|%#"]/, '\\\\\0')
    end

    def default_open_command
      if !get_bool('&hidden') && get_bool('&modified')
        'sp'
      else
        'e'
      end
    end

    def ensure_appropriate_window_selection
      # normally we try to open the selection in the current window, but there
      # is one exception:
      #
      # - we don't touch any "unlisted" buffer with buftype "nofile" (such as
      #   NERDTree or MiniBufExplorer); this is to avoid things like the "Not
      #   enough room" error which occurs when trying to open in a split in a
      #   shallow (potentially 1-line) buffer like MiniBufExplorer is current
      #
      # Other "unlisted" buffers, such as those with buftype "help" are treated
      # normally.
      initial = $curwin
      while true do
        break unless ::VIM::evaluate('&buflisted').to_i == 0 &&
          ::VIM::evaluate('&buftype').to_s == 'nofile'
        ::VIM::command 'wincmd w'     # try next window
        break if $curwin == initial # have already tried all
      end
    end

    def open_selection selection, options = {}
      command = options[:command] || default_open_command
      selection = File.expand_path selection, @path
      selection = relative_path_under_working_directory selection
      selection = sanitize_path_string selection
      ensure_appropriate_window_selection
      ::VIM::command "silent #{command} #{selection}"
    end

    def map key, function, param = nil
      ::VIM::command "noremap <silent> <buffer> #{key} " \
        ":call CommandT#{function}(#{param})<CR>"
    end

    def xterm?
      !!(::VIM::evaluate('&term') =~ /\Axterm/)
    end

    def vt100?
      !!(::VIM::evaluate('&term') =~ /\Avt100/)
    end

    def register_for_key_presses
      # "normal" keys (interpreted literally)
      numbers     = ('0'..'9').to_a.join
      lowercase   = ('a'..'z').to_a.join
      uppercase   = lowercase.upcase
      punctuation = '<>`@#~!"$%&/()=+*-_.,;:?\\\'{}[] ' # and space
      (numbers + lowercase + uppercase + punctuation).each_byte do |b|
        map "<Char-#{b}>", 'HandleKey', b
      end

      # "special" keys (overridable by settings)
      { 'Backspace'             => '<BS>',
        'Delete'                => '<Del>',
        'AcceptSelection'       => '<CR>',
        'AcceptSelectionSplit'  => ['<C-CR>', '<C-s>'],
        'AcceptSelectionTab'    => '<C-t>',
        'AcceptSelectionVSplit' => '<C-v>',
        'ToggleFocus'           => '<Tab>',
        'Cancel'                => ['<C-c>', '<Esc>'],
        'SelectNext'            => ['<C-n>', '<C-j>', '<Down>'],
        'SelectPrev'            => ['<C-p>', '<C-k>', '<Up>'],
        'Clear'                 => '<C-u>',
        'CursorLeft'            => ['<Left>', '<C-h>'],
        'CursorRight'           => ['<Right>', '<C-l>'],
        'CursorEnd'             => '<C-e>',
        'CursorStart'           => '<C-a>' }.each do |key, value|
        if override = get_list_or_string("g:CommandT#{key}Map")
          [override].flatten.each do |mapping|
            map mapping, key
          end
        else
          [value].flatten.each do |mapping|
            map mapping, key unless mapping == '<Esc>' && (xterm? || vt100?)
          end
        end
      end
    end

    # Returns the desired maximum number of matches, based on available
    # vertical space and the g:CommandTMaxHeight option.
    def match_limit
      limit = VIM::Screen.lines - 5
      limit = 1 if limit < 0
      limit = [limit, @max_height].min if @max_height > 0
      limit
    end

    def list_matches
      matches = @active_finder.sorted_matches_for @prompt.abbrev, :limit => match_limit
      @match_window.matches = matches
    end
  end # class Controller
end # module commandT
ruby/command-t/extconf.rb	[[[1
32
# Copyright 2010 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'mkmf'

def missing item
  puts "couldn't find #{item} (required)"
  exit 1
end

have_header('ruby.h') or missing('ruby.h')
create_makefile('ext')
ruby/command-t/finder/buffer_finder.rb	[[[1
35
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/ext' # CommandT::Matcher
require 'command-t/scanner/buffer_scanner'
require 'command-t/finder'

module CommandT
  class BufferFinder < Finder
    def initialize
      @scanner = BufferScanner.new
      @matcher = Matcher.new @scanner, :always_show_dot_files => true
    end
  end # class BufferFinder
end # CommandT
ruby/command-t/finder/file_finder.rb	[[[1
35
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/ext' # CommandT::Matcher
require 'command-t/finder'
require 'command-t/scanner/file_scanner'

module CommandT
  class FileFinder < Finder
    def initialize path = Dir.pwd, options = {}
      @scanner = FileScanner.new path, options
      @matcher = Matcher.new @scanner, options
    end
  end # class FileFinder
end # CommandT
ruby/command-t/finder.rb	[[[1
52
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/ext' # CommandT::Matcher

module CommandT
  # Encapsulates a Scanner instance (which builds up a list of available files
  # in a directory) and a Matcher instance (which selects from that list based
  # on a search string).
  #
  # Specialized subclasses use different kinds of scanners adapted for
  # different kinds of search (files, buffers).
  class Finder
    def initialize path = Dir.pwd, options = {}
      raise RuntimeError, 'Subclass responsibility'
    end

    # Options:
    #   :limit (integer): limit the number of returned matches
    def sorted_matches_for str, options = {}
      @matcher.sorted_matches_for str, options
    end

    def flush
      @scanner.flush
    end

    def path= path
      @scanner.path = path
    end
  end # class Finder
end # CommandT
ruby/command-t/match_window.rb	[[[1
387
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'ostruct'
require 'command-t/settings'

module CommandT
  class MatchWindow
    @@selection_marker  = '> '
    @@marker_length     = @@selection_marker.length
    @@unselected_marker = ' ' * @@marker_length
    @@buffer            = nil

    def initialize options = {}
      @prompt = options[:prompt]
      @reverse_list = options[:match_window_reverse]

      # save existing window dimensions so we can restore them later
      @windows = []
      (0..(::VIM::Window.count - 1)).each do |i|
        window = OpenStruct.new :index => i, :height => ::VIM::Window[i].height
        @windows << window
      end

      # global settings (must manually save and restore)
      @settings = Settings.new
      ::VIM::set_option 'timeout'         # ensure mappings timeout
      ::VIM::set_option 'timeoutlen=0'    # respond immediately to mappings
      ::VIM::set_option 'nohlsearch'      # don't highlight search strings
      ::VIM::set_option 'noinsertmode'    # don't make Insert mode the default
      ::VIM::set_option 'noshowcmd'       # don't show command info on last line
      ::VIM::set_option 'report=9999'     # don't show "X lines changed" reports
      ::VIM::set_option 'sidescroll=0'    # don't sidescroll in jumps
      ::VIM::set_option 'sidescrolloff=0' # don't sidescroll automatically
      ::VIM::set_option 'noequalalways'   # don't auto-balance window sizes

      # show match window
      split_location = options[:match_window_at_top] ? 'topleft' : 'botright'
      if @@buffer # still have buffer from last time
        ::VIM::command "silent! #{split_location} #{@@buffer.number}sbuffer"
        raise "Can't re-open GoToFile buffer" unless $curbuf.number == @@buffer.number
        $curwin.height = 1
      else        # creating match window for first time and set it up
        split_command = "silent! #{split_location} 1split GoToFile"
        [
          split_command,
          'setlocal bufhidden=unload',  # unload buf when no longer displayed
          'setlocal buftype=nofile',    # buffer is not related to any file
          'setlocal nomodifiable',      # prevent manual edits
          'setlocal noswapfile',        # don't create a swapfile
          'setlocal nowrap',            # don't soft-wrap
          'setlocal nonumber',          # don't show line numbers
          'setlocal nolist',            # don't use List mode (visible tabs etc)
          'setlocal foldcolumn=0',      # don't show a fold column at side
          'setlocal foldlevel=99',      # don't fold anything
          'setlocal nocursorline',      # don't highlight line cursor is on
          'setlocal nospell',           # spell-checking off
          'setlocal nobuflisted',       # don't show up in the buffer list
          'setlocal textwidth=0'        # don't hard-wrap (break long lines)
        ].each { |command| ::VIM::command command }

        # sanity check: make sure the buffer really was created
        raise "Can't find GoToFile buffer" unless $curbuf.name.match /GoToFile\z/
        @@buffer = $curbuf
      end

      # syntax coloring
      if VIM::has_syntax?
        ::VIM::command "syntax match CommandTSelection \"^#{@@selection_marker}.\\+$\""
        ::VIM::command 'syntax match CommandTNoEntries "^-- NO MATCHES --$"'
        ::VIM::command 'syntax match CommandTNoEntries "^-- NO SUCH FILE OR DIRECTORY --$"'
        ::VIM::command 'highlight link CommandTSelection Visual'
        ::VIM::command 'highlight link CommandTNoEntries Error'
        ::VIM::evaluate 'clearmatches()'

        # hide cursor
        @cursor_highlight = get_cursor_highlight
        hide_cursor
      end

      # perform cleanup using an autocmd to ensure we don't get caught out
      # by some unexpected means of dismissing or leaving the Command-T window
      # (eg. <C-W q>, <C-W k> etc)
      ::VIM::command 'autocmd! * <buffer>'
      ::VIM::command 'autocmd BufLeave <buffer> ruby $command_t.leave'
      ::VIM::command 'autocmd BufUnload <buffer> ruby $command_t.unload'

      @has_focus  = false
      @selection  = nil
      @abbrev     = ''
      @window     = $curwin
    end

    def close
      # Workaround for upstream bug in Vim 7.3 on some platforms
      #
      # On some platforms, $curbuf.number always returns 0. One workaround is
      # to build Vim with --disable-largefile, but as this is producing lots of
      # support requests, implement the following fallback to the buffer name
      # instead, at least until upstream gets fixed.
      #
      # For more details, see: https://wincent.com/issues/1617
      if $curbuf.number == 0
        # use bwipeout as bunload fails if passed the name of a hidden buffer
        ::VIM::command 'bwipeout! GoToFile'
        @@buffer = nil
      else
        ::VIM::command "bunload! #{@@buffer.number}"
      end
    end

    def leave
      close
      unload
    end

    def unload
      restore_window_dimensions
      @settings.restore
      @prompt.dispose
      show_cursor
    end

    def add! char
      @abbrev += char
    end

    def backspace!
      @abbrev.chop!
    end

    def select_next
      if @selection < @matches.length - 1
        @selection += 1
        print_match(@selection - 1) # redraw old selection (removes marker)
        print_match(@selection)     # redraw new selection (adds marker)
        move_cursor_to_selected_line
      else
        # (possibly) loop or scroll
      end
    end

    def select_prev
      if @selection > 0
        @selection -= 1
        print_match(@selection + 1) # redraw old selection (removes marker)
        print_match(@selection)     # redraw new selection (adds marker)
        move_cursor_to_selected_line
      else
        # (possibly) loop or scroll
      end
    end

    def matches= matches
      matches = matches.reverse if @reverse_list
      if matches != @matches
        @matches = matches
        @selection = @reverse_list ? @matches.length - 1 : 0
        print_matches
        move_cursor_to_selected_line
      end
    end

    def focus
      unless @has_focus
        @has_focus = true
        if VIM::has_syntax?
          ::VIM::command 'highlight link CommandTSelection Search'
        end
      end
    end

    def unfocus
      if @has_focus
        @has_focus = false
        if VIM::has_syntax?
          ::VIM::command 'highlight link CommandTSelection Visual'
        end
      end
    end

    def find char
      # is this a new search or the continuation of a previous one?
      now = Time.now
      if @last_key_time.nil? or @last_key_time < (now - 0.5)
        @find_string = char
      else
        @find_string += char
      end
      @last_key_time = now

      # see if there's anything up ahead that matches
      @matches.each_with_index do |match, idx|
        if match[0, @find_string.length].casecmp(@find_string) == 0
          old_selection = @selection
          @selection = idx
          print_match(old_selection)  # redraw old selection (removes marker)
          print_match(@selection)     # redraw new selection (adds marker)
          break
        end
      end
    end

    # Returns the currently selected item as a String.
    def selection
      @matches[@selection]
    end

    def print_no_such_file_or_directory
      print_error 'NO SUCH FILE OR DIRECTORY'
    end

  private

    def move_cursor_to_selected_line
      # on some non-GUI terminals, the cursor doesn't hide properly
      # so we move the cursor to prevent it from blinking away in the
      # upper-left corner in a distracting fashion
      @window.cursor = [@selection + 1, 0]
    end

    def print_error msg
      return unless VIM::Window.select(@window)
      unlock
      clear
      @window.height = 1
      @@buffer[1] = "-- #{msg} --"
      lock
    end

    def restore_window_dimensions
      # sort from tallest to shortest
      @windows.sort! { |a, b| b.height <=> a.height }

      # starting with the tallest ensures that there are no constraints
      # preventing windows on the side of vertical splits from regaining
      # their original full size
      @windows.each do |w|
        # beware: window may be nil
        window = ::VIM::Window[w.index]
        window.height = w.height if window
      end
    end

    def match_text_for_idx idx
      match = truncated_match @matches[idx]
      if idx == @selection
        prefix = @@selection_marker
        suffix = padding_for_selected_match match
      else
        prefix = @@unselected_marker
        suffix = ''
      end
      prefix + match + suffix
    end

    # Print just the specified match.
    def print_match idx
      return unless VIM::Window.select(@window)
      unlock
      @@buffer[idx + 1] = match_text_for_idx idx
      lock
    end

    # Print all matches.
    def print_matches
      match_count = @matches.length
      if match_count == 0
        print_error 'NO MATCHES'
      else
        return unless VIM::Window.select(@window)
        unlock
        clear
        actual_lines = 1
        @window_width = @window.width # update cached value
        max_lines = VIM::Screen.lines - 5
        max_lines = 1 if max_lines < 0
        actual_lines = match_count > max_lines ? max_lines : match_count
        @window.height = actual_lines
        (1..actual_lines).each do |line|
          idx = line - 1
          if @@buffer.count >= line
            @@buffer[line] = match_text_for_idx idx
          else
            @@buffer.append line - 1, match_text_for_idx(idx)
          end
        end
        lock
      end
    end

    # Prepare padding for match text (trailing spaces) so that selection
    # highlighting extends all the way to the right edge of the window.
    def padding_for_selected_match str
      len = str.length
      if len >= @window_width - @@marker_length
        ''
      else
        ' ' * (@window_width - @@marker_length - len)
      end
    end

    # Convert "really/long/path" into "really...path" based on available
    # window width.
    def truncated_match str
      len = str.length
      available_width = @window_width - @@marker_length
      return str if len <= available_width
      left = (available_width / 2) - 1
      right = (available_width / 2) - 2 + (available_width % 2)
      str[0, left] + '...' + str[-right, right]
    end

    def clear
      # range = % (whole buffer)
      # action = d (delete)
      # register = _ (black hole register, don't record deleted text)
      ::VIM::command 'silent %d _'
    end

    def get_cursor_highlight
      # as :highlight returns nothing and only prints,
      # must redirect its output to a variable
      ::VIM::command 'silent redir => g:command_t_cursor_highlight'

      # force 0 verbosity to ensure origin information isn't printed as well
      ::VIM::command 'silent! 0verbose highlight Cursor'
      ::VIM::command 'silent redir END'

      # there are 3 possible formats to check for, each needing to be
      # transformed in a certain way in order to reapply the highlight:
      #   Cursor xxx guifg=bg guibg=fg      -> :hi! Cursor guifg=bg guibg=fg
      #   Cursor xxx links to SomethingElse -> :hi! link Cursor SomethingElse
      #   Cursor xxx cleared                -> :hi! clear Cursor
      highlight = ::VIM::evaluate 'g:command_t_cursor_highlight'
      if highlight =~ /^Cursor\s+xxx\s+links to (\w+)/
        "link Cursor #{$~[1]}"
      elsif highlight =~ /^Cursor\s+xxx\s+cleared/
        'clear Cursor'
      elsif highlight =~ /Cursor\s+xxx\s+(.+)/
        "Cursor #{$~[1]}"
      else # likely cause E411 Cursor highlight group not found
        nil
      end
    end

    def hide_cursor
      if @cursor_highlight
        ::VIM::command 'highlight Cursor NONE'
      end
    end

    def show_cursor
      if @cursor_highlight
        ::VIM::command "highlight #{@cursor_highlight}"
      end
    end

    def lock
      ::VIM::command 'setlocal nomodifiable'
    end

    def unlock
      ::VIM::command 'setlocal modifiable'
    end
  end
end
ruby/command-t/prompt.rb	[[[1
165
# Copyright 2010 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module CommandT
  # Abuse the status line as a prompt.
  class Prompt
    attr_accessor :abbrev

    def initialize
      @abbrev     = ''  # abbreviation entered so far
      @col        = 0   # cursor position
      @has_focus  = false
    end

    # Erase whatever is displayed in the prompt line,
    # effectively disposing of the prompt
    def dispose
      ::VIM::command 'echo'
      ::VIM::command 'redraw'
    end

    # Clear any entered text.
    def clear!
      @abbrev = ''
      @col    = 0
      redraw
    end

    # Insert a character at (before) the current cursor position.
    def add! char
      left, cursor, right = abbrev_segments
      @abbrev = left + char + cursor + right
      @col += 1
      redraw
    end

    # Delete a character to the left of the current cursor position.
    def backspace!
      if @col > 0
        left, cursor, right = abbrev_segments
        @abbrev = left.chop! + cursor + right
        @col -= 1
        redraw
      end
    end

    # Delete a character at the current cursor position.
    def delete!
      if @col < @abbrev.length
        left, cursor, right = abbrev_segments
        @abbrev = left + right
        redraw
      end
    end

    def cursor_left
      if @col > 0
        @col -= 1
        redraw
      end
    end

    def cursor_right
      if @col < @abbrev.length
        @col += 1
        redraw
      end
    end

    def cursor_end
      if @col < @abbrev.length
        @col = @abbrev.length
        redraw
      end
    end

    def cursor_start
      if @col != 0
        @col = 0
        redraw
      end
    end

    def redraw
      if @has_focus
        prompt_highlight = 'Comment'
        normal_highlight = 'None'
        cursor_highlight = 'Underlined'
      else
        prompt_highlight = 'NonText'
        normal_highlight = 'NonText'
        cursor_highlight = 'NonText'
      end
      left, cursor, right = abbrev_segments
      components = [prompt_highlight, '>>', 'None', ' ']
      components += [normal_highlight, left] unless left.empty?
      components += [cursor_highlight, cursor] unless cursor.empty?
      components += [normal_highlight, right] unless right.empty?
      components += [cursor_highlight, ' '] if cursor.empty?
      set_status *components
    end

    def focus
      unless @has_focus
        @has_focus = true
        redraw
      end
    end

    def unfocus
      if @has_focus
        @has_focus = false
        redraw
      end
    end

  private

    # Returns the @abbrev string divided up into three sections, any of
    # which may actually be zero width, depending on the location of the
    # cursor:
    #   - left segment (to left of cursor)
    #   - cursor segment (character at cursor)
    #   - right segment (to right of cursor)
    def abbrev_segments
      left    = @abbrev[0, @col]
      cursor  = @abbrev[@col, 1]
      right   = @abbrev[(@col + 1)..-1] || ''
      [left, cursor, right]
    end

    def set_status *args
      # see ':help :echo' for why forcing a redraw here helps
      # prevent the status line from getting inadvertantly cleared
      # after our echo commands
      ::VIM::command 'redraw'
      while (highlight = args.shift) and  (text = args.shift) do
        text = VIM::escape_for_single_quotes text
        ::VIM::command "echohl #{highlight}"
        ::VIM::command "echon '#{text}'"
      end
      ::VIM::command 'echohl None'
    end
  end # class Prompt
end # module CommandT
ruby/command-t/scanner/buffer_scanner.rb	[[[1
42
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim'
require 'command-t/vim/path_utilities'
require 'command-t/scanner'

module CommandT
  # Returns a list of all open buffers.
  class BufferScanner < Scanner
    include VIM::PathUtilities

    def paths
      (0..(::VIM::Buffer.count - 1)).map do |n|
        buffer = ::VIM::Buffer[n]
        if buffer.name # beware, may be nil
          relative_path_under_working_directory buffer.name
        end
      end.compact
    end
  end # class BufferScanner
end # module CommandT
ruby/command-t/scanner/file_scanner.rb	[[[1
94
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim'
require 'command-t/scanner'

module CommandT
  # Reads the current directory recursively for the paths to all regular files.
  class FileScanner < Scanner
    class FileLimitExceeded < ::RuntimeError; end

    def initialize path = Dir.pwd, options = {}
      @path                 = path
      @max_depth            = options[:max_depth] || 15
      @max_files            = options[:max_files] || 10_000
      @scan_dot_directories = options[:scan_dot_directories] || false
    end

    def paths
      return @paths unless @paths.nil?
      begin
        @paths = []
        @depth = 0
        @files = 0
        @prefix_len = @path.chomp('/').length
        add_paths_for_directory @path, @paths
      rescue FileLimitExceeded
      end
      @paths
    end

    def flush
      @paths = nil
    end

    def path= str
      if @path != str
        @path = str
        flush
      end
    end

  private

    def path_excluded? path
      # first strip common prefix (@path) from path to match VIM's behavior
      path = path[(@prefix_len + 1)..-1]
      path = VIM::escape_for_single_quotes path
      ::VIM::evaluate("empty(expand(fnameescape('#{path}')))").to_i == 1
    end

    def add_paths_for_directory dir, accumulator
      Dir.foreach(dir) do |entry|
        next if ['.', '..'].include?(entry)
        path = File.join(dir, entry)
        unless path_excluded?(path)
          if File.file?(path)
            @files += 1
            raise FileLimitExceeded if @files > @max_files
            accumulator << path[@prefix_len + 1..-1]
          elsif File.directory?(path)
            next if @depth >= @max_depth
            next if (entry.match(/\A\./) && !@scan_dot_directories)
            @depth += 1
            add_paths_for_directory path, accumulator
            @depth -= 1
          end
        end
      end
    rescue Errno::EACCES
      # skip over directories for which we don't have access
    end
  end # class FileScanner
end # module CommandT
ruby/command-t/scanner.rb	[[[1
28
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim'

module CommandT
  class Scanner; end
end # module CommandT
ruby/command-t/settings.rb	[[[1
77
# Copyright 2010 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module CommandT
  # Convenience class for saving and restoring global settings.
  class Settings
    def initialize
      save
    end

    def save
      @timeoutlen     = get_number 'timeoutlen'
      @report         = get_number 'report'
      @sidescroll     = get_number 'sidescroll'
      @sidescrolloff  = get_number 'sidescrolloff'
      @timeout        = get_bool 'timeout'
      @equalalways    = get_bool 'equalalways'
      @hlsearch       = get_bool 'hlsearch'
      @insertmode     = get_bool 'insertmode'
      @showcmd        = get_bool 'showcmd'
    end

    def restore
      set_number 'timeoutlen', @timeoutlen
      set_number 'report', @report
      set_number 'sidescroll', @sidescroll
      set_number 'sidescrolloff', @sidescrolloff
      set_bool 'timeout', @timeout
      set_bool 'equalalways', @equalalways
      set_bool 'hlsearch', @hlsearch
      set_bool 'insertmode', @insertmode
      set_bool 'showcmd', @showcmd
    end

  private

    def get_number setting
      ::VIM::evaluate("&#{setting}").to_i
    end

    def get_bool setting
      ::VIM::evaluate("&#{setting}").to_i == 1
    end

    def set_number setting, value
      ::VIM::set_option "#{setting}=#{value}"
    end

    def set_bool setting, value
      if value
        ::VIM::set_option setting
      else
        ::VIM::set_option "no#{setting}"
      end
    end
  end # class Settings
end # module CommandT
ruby/command-t/stub.rb	[[[1
46
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module CommandT
  class Stub
    @@load_error = ['command-t.vim could not load the C extension',
                    'Please see INSTALLATION and TROUBLE-SHOOTING in the help',
                    'For more information type:    :help command-t']

    def show_file_finder
      warn *@@load_error
    end

    def flush
      warn *@@load_error
    end

  private

    def warn *msg
      ::VIM::command 'echohl WarningMsg'
      msg.each { |m| ::VIM::command "echo '#{m}'" }
      ::VIM::command 'echohl none'
    end
  end # class Stub
end # module CommandT
ruby/command-t/vim/path_utilities.rb	[[[1
40
# Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim'

module CommandT
  module VIM
    module PathUtilities

    private

      def relative_path_under_working_directory path
        # any path under the working directory will be specified as a relative
        # path to improve the readability of the buffer list etc
        pwd = File.expand_path(VIM::pwd) + '/'
        path.index(pwd) == 0 ? path[pwd.length..-1] : path
      end
    end # module PathUtilities
  end # module VIM
end # module CommandT
ruby/command-t/vim/screen.rb	[[[1
32
# Copyright 2010 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module CommandT
  module VIM
    module Screen
      def self.lines
        ::VIM::evaluate('&lines').to_i
      end
    end # module Screen
  end # module VIM
end # module CommandT
ruby/command-t/vim/window.rb	[[[1
38
# Copyright 2010 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module CommandT
  module VIM
    class Window
      def self.select window
        return true if $curwin == window
        initial = $curwin
        while true do
          ::VIM::command 'wincmd w'           # cycle through windows
          return true if $curwin == window    # have selected desired window
          return false if $curwin == initial  # have already looped through all
        end
      end
    end # class Window
  end # module VIM
end # module CommandT
ruby/command-t/vim.rb	[[[1
43
# Copyright 2010 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'command-t/vim/screen'
require 'command-t/vim/window'

module CommandT
  module VIM
    def self.has_syntax?
      ::VIM::evaluate('has("syntax")').to_i != 0
    end

    def self.pwd
      ::VIM::evaluate 'getcwd()'
    end

    # Escape a string for safe inclusion in a Vim single-quoted string
    # (single quotes escaped by doubling, everything else is literal)
    def self.escape_for_single_quotes str
      str.gsub "'", "''"
    end
  end # module VIM
end # module CommandT
ruby/command-t/ext.c	[[[1
65
// Copyright 2010 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include "match.h"
#include "matcher.h"

VALUE mCommandT         = 0; // module CommandT
VALUE cCommandTMatch    = 0; // class CommandT::Match
VALUE cCommandTMatcher  = 0; // class CommandT::Matcher

VALUE CommandT_option_from_hash(const char *option, VALUE hash)
{
    if (NIL_P(hash))
        return Qnil;
    VALUE key = ID2SYM(rb_intern(option));
    if (rb_funcall(hash, rb_intern("has_key?"), 1, key) == Qtrue)
        return rb_hash_aref(hash, key);
    else
        return Qnil;
}

void Init_ext()
{
    // module CommandT
    mCommandT = rb_define_module("CommandT");

    // class CommandT::Match
    cCommandTMatch = rb_define_class_under(mCommandT, "Match", rb_cObject);

    // methods
    rb_define_method(cCommandTMatch, "initialize", CommandTMatch_initialize, -1);
    rb_define_method(cCommandTMatch, "matches?", CommandTMatch_matches, 0);
    rb_define_method(cCommandTMatch, "to_s", CommandTMatch_to_s, 0);

    // attributes
    rb_define_attr(cCommandTMatch, "score", Qtrue, Qfalse); // reader: true, writer: false

    // class CommandT::Matcher
    cCommandTMatcher = rb_define_class_under(mCommandT, "Matcher", rb_cObject);

    // methods
    rb_define_method(cCommandTMatcher, "initialize", CommandTMatcher_initialize, -1);
    rb_define_method(cCommandTMatcher, "sorted_matches_for", CommandTMatcher_sorted_matches_for, 2);
    rb_define_method(cCommandTMatcher, "matches_for", CommandTMatcher_matches_for, 1);
}
ruby/command-t/match.c	[[[1
189
// Copyright 2010 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include "match.h"
#include "ext.h"
#include "ruby_compat.h"

// use a struct to make passing params during recursion easier
typedef struct
{
    char    *str_p;                 // pointer to string to be searched
    long    str_len;                // length of same
    char    *abbrev_p;              // pointer to search string (abbreviation)
    long    abbrev_len;             // length of same
    double  max_score_per_char;
    int     dot_file;               // boolean: true if str is a dot-file
    int     always_show_dot_files;  // boolean
    int     never_show_dot_files;   // boolean
} matchinfo_t;

double recursive_match(matchinfo_t *m,  // sharable meta-data
                       long str_idx,    // where in the path string to start
                       long abbrev_idx, // where in the search string to start
                       long last_idx,   // location of last matched character
                       double score)    // cumulative score so far
{
    double seen_score = 0;      // remember best score seen via recursion
    int dot_file_match = 0;     // true if abbrev matches a dot-file
    int dot_search = 0;         // true if searching for a dot

    for (long i = abbrev_idx; i < m->abbrev_len; i++)
    {
        char c = m->abbrev_p[i];
        if (c == '.')
            dot_search = 1;
        int found = 0;
        for (long j = str_idx; j < m->str_len; j++, str_idx++)
        {
            char d = m->str_p[j];
            if (d == '.')
            {
                if (j == 0 || m->str_p[j - 1] == '/')
                {
                    m->dot_file = 1;        // this is a dot-file
                    if (dot_search)         // and we are searching for a dot
                        dot_file_match = 1; // so this must be a match
                }
            }
            else if (d >= 'A' && d <= 'Z')
                d += 'a' - 'A'; // add 32 to downcase
            if (c == d)
            {
                found = 1;
                dot_search = 0;

                // calculate score
                double score_for_char = m->max_score_per_char;
                long distance = j - last_idx;
                if (distance > 1)
                {
                    double factor = 1.0;
                    char last = m->str_p[j - 1];
                    char curr = m->str_p[j]; // case matters, so get again
                    if (last == '/')
                        factor = 0.9;
                    else if (last == '-' ||
                            last == '_' ||
                            last == ' ' ||
                            (last >= '0' && last <= '9'))
                        factor = 0.8;
                    else if (last >= 'a' && last <= 'z' &&
                            curr >= 'A' && curr <= 'Z')
                        factor = 0.8;
                    else if (last == '.')
                        factor = 0.7;
                    else
                        // if no "special" chars behind char, factor diminishes
                        // as distance from last matched char increases
                        factor = (1.0 / distance) * 0.75;
                    score_for_char *= factor;
                }

                if (++j < m->str_len)
                {
                    // bump cursor one char to the right and
                    // use recursion to try and find a better match
                    double sub_score = recursive_match(m, j, i, last_idx, score);
                    if (sub_score > seen_score)
                        seen_score = sub_score;
                }

                score += score_for_char;
                last_idx = str_idx++;
                break;
            }
        }
        if (!found)
            return 0.0;
    }
    if (m->dot_file)
    {
        if (m->never_show_dot_files ||
            (!dot_file_match && !m->always_show_dot_files))
            return 0.0;
    }
    return (score > seen_score) ? score : seen_score;
}

// Match.new abbrev, string, options = {}
VALUE CommandTMatch_initialize(int argc, VALUE *argv, VALUE self)
{
    // process arguments: 2 mandatory, 1 optional
    VALUE str, abbrev, options;
    if (rb_scan_args(argc, argv, "21", &str, &abbrev, &options) == 2)
        options = Qnil;
    str             = StringValue(str);
    abbrev          = StringValue(abbrev); // already downcased by caller

    // check optional options hash for overrides
    VALUE always_show_dot_files = CommandT_option_from_hash("always_show_dot_files", options);
    VALUE never_show_dot_files = CommandT_option_from_hash("never_show_dot_files", options);

    matchinfo_t m;
    m.str_p                 = RSTRING_PTR(str);
    m.str_len               = RSTRING_LEN(str);
    m.abbrev_p              = RSTRING_PTR(abbrev);
    m.abbrev_len            = RSTRING_LEN(abbrev);
    m.max_score_per_char    = (1.0 / m.str_len + 1.0 / m.abbrev_len) / 2;
    m.dot_file              = 0;
    m.always_show_dot_files = always_show_dot_files == Qtrue;
    m.never_show_dot_files  = never_show_dot_files == Qtrue;

    // calculate score
    double score = 1.0;
    if (m.abbrev_len == 0) // special case for zero-length search string
    {
        // filter out dot files
        if (!m.always_show_dot_files)
        {
            for (long i = 0; i < m.str_len; i++)
            {
                char c = m.str_p[i];
                if (c == '.' && (i == 0 || m.str_p[i - 1] == '/'))
                {
                    score = 0.0;
                    break;
                }
            }
        }
    }
    else // normal case
        score = recursive_match(&m, 0, 0, 0, 0.0);

    // clean-up and final book-keeping
    rb_iv_set(self, "@score", rb_float_new(score));
    rb_iv_set(self, "@str", str);
    return Qnil;
}

VALUE CommandTMatch_matches(VALUE self)
{
    double score = NUM2DBL(rb_iv_get(self, "@score"));
    return score > 0 ? Qtrue : Qfalse;
}

VALUE CommandTMatch_to_s(VALUE self)
{
    return rb_iv_get(self, "@str");
}
ruby/command-t/matcher.c	[[[1
164
// Copyright 2010 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <stdlib.h> /* for qsort() */
#include <string.h> /* for strcmp() */
#include "matcher.h"
#include "ext.h"
#include "ruby_compat.h"

// comparison function for use with qsort
int comp_alpha(const void *a, const void *b)
{
    VALUE a_val = *(VALUE *)a;
    VALUE b_val = *(VALUE *)b;
    ID to_s = rb_intern("to_s");

    VALUE a_str = rb_funcall(a_val, to_s, 0);
    VALUE b_str = rb_funcall(b_val, to_s, 0);
    char *a_p = RSTRING_PTR(a_str);
    long a_len = RSTRING_LEN(a_str);
    char *b_p = RSTRING_PTR(b_str);
    long b_len = RSTRING_LEN(b_str);
    int order = 0;
    if (a_len > b_len)
    {
        order = strncmp(a_p, b_p, b_len);
        if (order == 0)
            order = 1; // shorter string (b) wins
    }
    else if (a_len < b_len)
    {
        order = strncmp(a_p, b_p, a_len);
        if (order == 0)
            order = -1; // shorter string (a) wins
    }
    else
        order = strncmp(a_p, b_p, a_len);
    return order;
}

// comparison function for use with qsort
int comp_score(const void *a, const void *b)
{
    VALUE a_val = *(VALUE *)a;
    VALUE b_val = *(VALUE *)b;
    ID score = rb_intern("score");
    double a_score = RFLOAT_VALUE(rb_funcall(a_val, score, 0));
    double b_score = RFLOAT_VALUE(rb_funcall(b_val, score, 0));
    if (a_score > b_score)
        return -1; // a scores higher, a should appear sooner
    else if (a_score < b_score)
        return 1;  // b scores higher, a should appear later
    else
        return comp_alpha(a, b);
}

VALUE CommandTMatcher_initialize(int argc, VALUE *argv, VALUE self)
{
    // process arguments: 1 mandatory, 1 optional
    VALUE scanner, options;
    if (rb_scan_args(argc, argv, "11", &scanner, &options) == 1)
        options = Qnil;
    if (NIL_P(scanner))
        rb_raise(rb_eArgError, "nil scanner");
    rb_iv_set(self, "@scanner", scanner);

    // check optional options hash for overrides
    VALUE always_show_dot_files = CommandT_option_from_hash("always_show_dot_files", options);
    if (always_show_dot_files != Qtrue)
        always_show_dot_files = Qfalse;
    VALUE never_show_dot_files = CommandT_option_from_hash("never_show_dot_files", options);
    if (never_show_dot_files != Qtrue)
        never_show_dot_files = Qfalse;
    rb_iv_set(self, "@always_show_dot_files", always_show_dot_files);
    rb_iv_set(self, "@never_show_dot_files", never_show_dot_files);
    return Qnil;
}

VALUE CommandTMatcher_sorted_matches_for(VALUE self, VALUE abbrev, VALUE options)
{
    // process optional options hash
    VALUE limit_option = CommandT_option_from_hash("limit", options);

    // get unsorted matches
    VALUE matches = CommandTMatcher_matches_for(self, abbrev);

    abbrev = StringValue(abbrev);
    if (RSTRING_LEN(abbrev) == 0 ||
        (RSTRING_LEN(abbrev) == 1 && RSTRING_PTR(abbrev)[0] == '.'))
        // alphabetic order if search string is only "" or "."
        qsort(RARRAY_PTR(matches), RARRAY_LEN(matches), sizeof(VALUE), comp_alpha);
    else
        // for all other non-empty search strings, sort by score
        qsort(RARRAY_PTR(matches), RARRAY_LEN(matches), sizeof(VALUE), comp_score);

    // apply optional limit option
    long limit = NIL_P(limit_option) ? 0 : NUM2LONG(limit_option);
    if (limit == 0 || RARRAY_LEN(matches) < limit)
        limit = RARRAY_LEN(matches);

    // will return an array of strings, not an array of Match objects
    for (long i = 0; i < limit; i++)
    {
        VALUE str = rb_funcall(RARRAY_PTR(matches)[i], rb_intern("to_s"), 0);
        RARRAY_PTR(matches)[i] = str;
    }

    // trim off any items beyond the limit
    if (limit < RARRAY_LEN(matches))
        (void)rb_funcall(matches, rb_intern("slice!"), 2, LONG2NUM(limit),
            LONG2NUM(RARRAY_LEN(matches) - limit));
    return matches;
}

VALUE CommandTMatcher_matches_for(VALUE self, VALUE abbrev)
{
    if (NIL_P(abbrev))
        rb_raise(rb_eArgError, "nil abbrev");
    VALUE matches = rb_ary_new();
    VALUE scanner = rb_iv_get(self, "@scanner");
    VALUE always_show_dot_files = rb_iv_get(self, "@always_show_dot_files");
    VALUE never_show_dot_files = rb_iv_get(self, "@never_show_dot_files");
    VALUE options = Qnil;
    if (always_show_dot_files == Qtrue)
    {
        options = rb_hash_new();
        rb_hash_aset(options, ID2SYM(rb_intern("always_show_dot_files")), always_show_dot_files);
    }
    else if (never_show_dot_files == Qtrue)
    {
        options = rb_hash_new();
        rb_hash_aset(options, ID2SYM(rb_intern("never_show_dot_files")), never_show_dot_files);
    }
    abbrev = rb_funcall(abbrev, rb_intern("downcase"), 0);
    VALUE paths = rb_funcall(scanner, rb_intern("paths"), 0);
    for (long i = 0, max = RARRAY_LEN(paths); i < max; i++)
    {
        VALUE path = RARRAY_PTR(paths)[i];
        VALUE match = rb_funcall(cCommandTMatch, rb_intern("new"), 3, path, abbrev, options);
        if (rb_funcall(match, rb_intern("matches?"), 0) == Qtrue)
            rb_funcall(matches, rb_intern("push"), 1, match);
    }
    return matches;
}
ruby/command-t/ext.h	[[[1
36
// Copyright 2010 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <ruby.h>

extern VALUE mCommandT;         // module CommandT
extern VALUE cCommandTMatch;    // class CommandT::Match
extern VALUE cCommandTMatcher;  // class CommandT::Matcher

// Encapsulates common pattern of checking for an option in an optional
// options hash. The hash itself may be nil, but an exception will be
// raised if it is not nil and not a hash.
VALUE CommandT_option_from_hash(const char *option, VALUE hash);

// Debugging macro.
#define ruby_inspect(obj) rb_funcall(rb_mKernel, rb_intern("p"), 1, obj)
ruby/command-t/match.h	[[[1
29
// Copyright 2010 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <ruby.h>

extern VALUE CommandTMatch_initialize(int argc, VALUE *argv, VALUE self);
extern VALUE CommandTMatch_matches(VALUE self);
extern VALUE CommandTMatch_score(VALUE self);
extern VALUE CommandTMatch_to_s(VALUE self);
ruby/command-t/matcher.h	[[[1
30
// Copyright 2010 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <ruby.h>

extern VALUE CommandTMatcher_initialize(int argc, VALUE *argv, VALUE self);
extern VALUE CommandTMatcher_sorted_matches_for(VALUE self, VALUE abbrev, VALUE options);

// most likely the function will be subsumed by the sorted_matcher_for function
extern VALUE CommandTMatcher_matches_for(VALUE self, VALUE abbrev);
ruby/command-t/ruby_compat.h	[[[1
49
// Copyright 2010 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <ruby.h>

// for compatibility with older versions of Ruby which don't declare RSTRING_PTR
#ifndef RSTRING_PTR
#define RSTRING_PTR(s) (RSTRING(s)->ptr)
#endif

// for compatibility with older versions of Ruby which don't declare RSTRING_LEN
#ifndef RSTRING_LEN
#define RSTRING_LEN(s) (RSTRING(s)->len)
#endif

// for compatibility with older versions of Ruby which don't declare RARRAY_PTR
#ifndef RARRAY_PTR
#define RARRAY_PTR(a) (RARRAY(a)->ptr)
#endif

// for compatibility with older versions of Ruby which don't declare RARRAY_LEN
#ifndef RARRAY_LEN
#define RARRAY_LEN(a) (RARRAY(a)->len)
#endif

// for compatibility with older versions of Ruby which don't declare RFLOAT_VALUE
#ifndef RFLOAT_VALUE
#define RFLOAT_VALUE(f) (RFLOAT(f)->value)
#endif
ruby/command-t/depend	[[[1
24
# Copyright 2010 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

CFLAGS += -std=c99 -Wall -Wextra -Wno-unused-parameter
doc/command-t.txt	[[[1
786
*command-t.txt* Command-T plug-in for Vim         *command-t*

CONTENTS                                        *command-t-contents*

 1. Introduction            |command-t-intro|
 2. Requirements            |command-t-requirements|
 3. Installation            |command-t-installation|
 3. Managing using Pathogen |command-t-pathogen|
 4. Trouble-shooting        |command-t-trouble-shooting|
 5. Usage                   |command-t-usage|
 6. Commands                |command-t-commands|
 7. Mappings                |command-t-mappings|
 8. Options                 |command-t-options|
 9. Authors                 |command-t-authors|
10. Website                 |command-t-website|
11. Donations               |command-t-donations|
12. License                 |command-t-license|
13. History                 |command-t-history|


INTRODUCTION                                    *command-t-intro*

The Command-T plug-in provides an extremely fast, intuitive mechanism for
opening files and buffers with a minimal number of keystrokes. It's named
"Command-T" because it is inspired by the "Go to File" window bound to
Command-T in TextMate.

Files are selected by typing characters that appear in their paths, and are
ordered by an algorithm which knows that characters that appear in certain
locations (for example, immediately after a path separator) should be given
more weight.

To search efficiently, especially in large projects, you should adopt a
"path-centric" rather than a "filename-centric" mentality. That is you should
think more about where the desired file is found rather than what it is
called. This means narrowing your search down by including some characters
from the upper path components rather than just entering characters from the
filename itself.

Screencasts demonstrating the plug-in can be viewed at:

  https://wincent.com/products/command-t


REQUIREMENTS                                    *command-t-requirements*

The plug-in requires Vim compiled with Ruby support, a compatible Ruby
installation at the operating system level, and a C compiler to build
the Ruby extension.


1. Vim compiled with Ruby support

You can check for Ruby support by launching Vim with the --version switch:

  vim --version

If "+ruby" appears in the version information then your version of Vim has
Ruby support.

Another way to check is to simply try using the :ruby command from within Vim
itself:

  :ruby 1

If your Vim lacks support you'll see an error message like this:

  E319: Sorry, the command is not available in this version

The version of Vim distributed with Mac OS X does not include Ruby support,
while MacVim does; it is available from:

  http://github.com/b4winckler/macvim/downloads

For Windows users, the Vim 7.2 executable available from www.vim.org does
include Ruby support, and is recommended over version 7.3 (which links against
Ruby 1.9, but apparently has some bugs that need to be resolved).


2. Ruby

In addition to having Ruby support in Vim, your system itself must have a
compatible Ruby install. "Compatible" means the same version as Vim itself
links against. If you use a different version then Command-T is unlikely
to work (see TROUBLE-SHOOTING below).

On Mac OS X Snow Leopard, the system comes with Ruby 1.8.7 and all recent
versions of MacVim (the 7.2 snapshots and 7.3) are linked against it.

On Linux and similar platforms, the linked version of Ruby will depend on
your distribution. You can usually find this out by examining the
compilation and linking flags displayed by the |:version| command in Vim, and
by looking at the output of:

  :ruby puts RUBY_VERSION

A suitable Ruby environment for Windows can be installed using the Ruby
1.8.7-p299 RubyInstaller available at:

  http://rubyinstaller.org/downloads/archives

If using RubyInstaller be sure to download the installer executable, not the
7-zip archive. When installing mark the checkbox "Add Ruby executables to your
PATH" so that Vim can find them.


3. C compiler

Part of Command-T is implemented in C as a Ruby extension for speed, allowing
it to work responsively even on directory hierarchies containing enormous
numbers of files. As such, a C compiler is required in order to build the
extension and complete the installation.

On Mac OS X, this can be obtained by installing the Xcode Tools that come on
the Mac OS X install disc.

On Windows, the RubyInstaller Development Kit can be used to conveniently
install the necessary tool chain:

  http://rubyinstaller.org/downloads/archives

At the time of writing, the appropriate development kit for use with Ruby
1.8.7 is DevKit-3.4.5r3-20091110.

To use the Development Kit extract the archive contents to your C:\Ruby
folder.


INSTALLATION                                    *command-t-installation*

Command-T is distributed as a "vimball" which means that it can be installed
by opening it in Vim and then sourcing it:

  :e command-t.vba
  :so %

The files will be installed in your |'runtimepath'|. To check where this is
you can issue:

  :echo &rtp

The C extension must then be built, which can be done from the shell. If you
use a typical |'runtimepath'| then the files were installed inside ~/.vim and
you can build the extension with:

  cd ~/.vim/ruby/command-t
  ruby extconf.rb
  make

Note: If you are an RVM user, you must perform the build using the same
version of Ruby that Vim itself is linked against. This will often be the
system Ruby, which can be selected before issuing the "make" command with:

  rvm use system


MANAGING USING PATHOGEN                         *command-t-pathogen*

Pathogen is a plugin that allows you to maintain plugin installations in
separate, isolated subdirectories under the "bundle" directory in your
|'runtimepath'|. The following examples assume that you already have
Pathogen installed and configured, and that you are installing into
~/.vim/bundle. For more information about Pathogen, see:

  http://www.vim.org/scripts/script.php?script_id=2332

If you manage your entire ~/.vim folder using Git then you can add the
Command-T repository as a submodule:

  cd ~/.vim
  git submodule add git://git.wincent.com/command-t.git bundle/command-t
  git submodule init

Or if you just wish to do a simple clone instead of using submodules:

  cd ~/.vim
  git clone git://git.wincent.com/command-t.git bundle/command-t

Once you have a local copy of the repository you can update it at any time
with:

  cd ~/.vim/bundle/command-t
  git pull

Or you can switch to a specific release with:

  cd ~/.vim/bundle/command-t
  git checkout 0.8b

After installing or updating you must build the extension:

  cd ~/.vim/bundle/command-t
  rake make

While the Vimball installation automatically generates the help tags, under
Pathogen it is necessary to do so explicitly from inside Vim:

  :call pathogen#helptags()


TROUBLE-SHOOTING                                *command-t-trouble-shooting*

Most installation problems are caused by a mismatch between the version of
Ruby on the host operating system, and the version of Ruby that Vim itself
linked against at compile time. For example, if one is 32-bit and the other is
64-bit, or one is from the Ruby 1.9 series and the other is from the 1.8
series, then the plug-in is not likely to work.

As such, on Mac OS X, I recommend using the standard Ruby that comes with the
system (currently 1.8.7) along with the latest version of MacVim (currently
version 7.3). If you wish to use custom builds of Ruby or of MacVim (not
recommmended) then you will have to take extra care to ensure that the exact
same Ruby environment is in effect when building Ruby, Vim and the Command-T
extension.

For Windows, the following combination is known to work:

  - Vim 7.2 from http://www.vim.org/download.php:
      ftp://ftp.vim.org/pub/vim/pc/gvim72.exe
  - Ruby 1.8.7-p299 from http://rubyinstaller.org/downloads/archives:
      http://rubyforge.org/frs/download.php/71492/rubyinstaller-1.8.7-p299.exe
  - DevKit 3.4.5r3-20091110 from http://rubyinstaller.org/downloads/archives:
      http://rubyforge.org/frs/download.php/66888/devkit-3.4.5r3-20091110.7z

If a problem occurs the first thing you should do is inspect the output of:

  ruby extconf.rb
  make

During the installation, and:

  vim --version

And compare the compilation and linker flags that were passed to the
extension and to Vim itself when they were built. If the Ruby-related
flags or architecture flags are different then it is likely that something
has changed in your Ruby environment and the extension may not work until
you eliminate the discrepancy.


USAGE                                           *command-t-usage*

Bring up the Command-T file window by typing:

  <Leader>t

This mapping is set up automatically for you, provided you do not already have
a mapping for <Leader>t or |:CommandT|. You can also bring up the file window
by issuing the command:

  :CommandT

A prompt will appear at the bottom of the screen along with a file window
showing all of the files in the current directory (as returned by the
|:pwd| command).

For the most efficient file navigation within a project it's recommended that
you |:cd| into the root directory of your project when starting to work on it.
If you wish to open a file from outside of the project folder you can pass in
an optional path argument (relative or absolute) to |:CommandT|:

  :CommandT ../path/to/other/files

Type letters in the prompt to narrow down the selection, showing only the
files whose paths contain those letters in the specified order. Letters do not
need to appear consecutively in a path in order for it to be classified as a
match.

Once the desired file has been selected it can be opened by pressing <CR>.
(By default files are opened in the current window, but there are other
mappings that you can use to open in a vertical or horizontal split, or in
a new tab.) Note that if you have |'nohidden'| set and there are unsaved
changes in the current window when you press <CR> then opening in the current
window would fail; in this case Command-T will open the file in a new split.

The following mappings are active when the prompt has focus:

    <BS>        delete the character to the left of the cursor
    <Del>       delete the character at the cursor
    <Left>      move the cursor one character to the left
    <C-h>       move the cursor one character to the left
    <Right>     move the cursor one character to the right
    <C-l>       move the cursor one character to the right
    <C-a>       move the cursor to the start (left)
    <C-e>       move the cursor to the end (right)
    <C-u>       clear the contents of the prompt
    <Tab>       change focus to the file listing

The following mappings are active when the file listing has focus:

    <Tab>       change focus to the prompt

The following mappings are active when either the prompt or the file listing
has focus:

    <CR>        open the selected file
    <C-CR>      open the selected file in a new split window
    <C-s>       open the selected file in a new split window
    <C-v>       open the selected file in a new vertical split window
    <C-t>       open the selected file in a new tab
    <C-j>       select next file in the file listing
    <C-n>       select next file in the file listing
    <Down>      select next file in the file listing
    <C-k>       select previous file in the file listing
    <C-p>       select previous file in the file listing
    <Up>        select previous file in the file listing
    <C-c>       cancel (dismisses file listing)

The following is also available on terminals which support it:

    <Esc>       cancel (dismisses file listing)

Note that the default mappings can be overriden by setting options in your
~/.vimrc file (see the OPTIONS section for a full list of available options).

In addition, when the file listing has focus, typing a character will cause
the selection to jump to the first path which begins with that character.
Typing multiple characters consecutively can be used to distinguish between
paths which begin with the same prefix.


COMMANDS                                        *command-t-commands*

                                                *:CommandT*
|:CommandT|     Brings up the Command-T file window, starting in the
                current working directory as returned by the|:pwd|
                command.

                                                *:CommandTBuffer*
|:CommandTBuffer|Brings up the Command-T buffer window.
                This works exactly like the standard file window,
                except that the selection is limited to files that
                you already have open in buffers.

                                                *:CommandTFlush*
|:CommandTFlush|Instructs the plug-in to flush its path cache, causing
                the directory to be rescanned for new or deleted paths
                the next time the file window is shown. In addition, all
                configuration settings are re-evaluated, causing any
                changes made to settings via the |:let| command to be picked
                up.


MAPPINGS                                        *command-t-mappings*

By default Command-T comes with only two mappings:

  <Leader>t     bring up the Command-T file window
  <Leader>b     bring up the Command-T buffer window

However, Command-T won't overwrite a pre-existing mapping so if you prefer
to define different mappings use lines like these in your ~/.vimrc:

  nmap <silent> <Leader>t :CommandT<CR>
  nmap <silent> <Leader>b :CommandTBuffer<CR>

Replacing "<Leader>t" or "<Leader>b" with your mapping of choice.

Note that in the case of MacVim you actually can map to Command-T (written
as <D-t> in Vim) in your ~/.gvimrc file if you first unmap the existing menu
binding of Command-T to "New Tab":

  if has("gui_macvim")
    macmenu &File.New\ Tab key=<nop>
    map <D-t> :CommandT<CR>
  endif

When the Command-T window is active a number of other additional mappings
become available for doing things like moving between and selecting matches.
These are fully described above in the USAGE section, and settings for
overriding the mappings are listed below under OPTIONS.


OPTIONS                                         *command-t-options*

A number of options may be set in your ~/.vimrc to influence the behaviour of
the plug-in. To set an option, you include a line like this in your ~/.vimrc:

    let g:CommandTMaxFiles=20000

To have Command-T pick up new settings immediately (that is, without having
to restart Vim) you can issue the |:CommandTFlush| command after making
changes via |:let|.

Following is a list of all available options:

                                               *g:CommandTMaxFiles*
  |g:CommandTMaxFiles|                           number (default 10000)

      The maximum number of files that will be considered when scanning the
      current directory. Upon reaching this number scanning stops. This
      limit applies only to file listings and is ignored for buffer
      listings.

                                               *g:CommandTMaxDepth*
  |g:CommandTMaxDepth|                           number (default 15)

      The maximum depth (levels of recursion) to be explored when scanning the
      current directory. Any directories at levels beyond this depth will be
      skipped.

                                               *g:CommandTMaxHeight*
  |g:CommandTMaxHeight|                          number (default: 0)

      The maximum height in lines the match window is allowed to expand to.
      If set to 0, the window will occupy as much of the available space as
      needed to show matching entries.

                                               *g:CommandTAlwaysShowDotFiles*
  |g:CommandTAlwaysShowDotFiles|                 boolean (default: 0)

      When showing the file listing Command-T will by default show dot-files
      only if the entered search string contains a dot that could cause a
      dot-file to match. When set to a non-zero value, this setting instructs
      Command-T to always include matching dot-files in the match list
      regardless of whether the search string contains a dot. See also
      |g:CommandTNeverShowDotFiles|. Note that this setting only influences
      the file listing; the buffer listing treats dot-files like any other
      file.

                                               *g:CommandTNeverShowDotFiles*
  |g:CommandTNeverShowDotFiles|                  boolean (default: 0)

      In the file listing, Command-T will by default show dot-files if the
      entered search string contains a dot that could cause a dot-file to
      match. When set to a non-zero value, this setting instructs Command-T to
      never show dot-files under any circumstances. Note that it is
      contradictory to set both this setting and
      |g:CommandTAlwaysShowDotFiles| to true, and if you do so Vim will suffer
      from headaches, nervous twitches, and sudden mood swings. This setting
      has no effect in buffer listings, where dot files are treated like any
      other file.

                                               *g:CommandTScanDotDirectories*
  |g:CommandTScanDotDirectories|                 boolean (default: 0)

      Normally Command-T will not recurse into "dot-directories" (directories
      whose names begin with a dot) while performing its initial scan. Set
      this setting to a non-zero value to override this behavior and recurse.
      Note that this setting is completely independent of the
      |g:CommandTAlwaysShowDotFiles| and |g:CommandTNeverShowDotFiles|
      settings; those apply only to the selection and display of matches
      (after scanning has been performed), whereas
      |g:CommandTScanDotDirectories| affects the behaviour at scan-time.

      Note also that even with this setting off you can still use Command-T to
      open files inside a "dot-directory" such as ~/.vim, but you have to use
      the |:cd| command to change into that directory first. For example:

        :cd ~/.vim
        :CommandT

                                               *g:CommandTMatchWindowAtTop*
  |g:CommandTMatchWindowAtTop|                   boolean (default: 0)

      When this setting is off (the default) the match window will appear at
      the bottom so as to keep it near to the prompt. Turning it on causes the
      match window to appear at the top instead. This may be preferable if you
      want the best match (usually the first one) to appear in a fixed location
      on the screen rather than moving as the number of matches changes during
      typing.

                                                *g:CommandTMatchWindowReverse*
  |g:CommandTMatchWindowReverse|                  boolean (default: 0)

      When this setting is off (the default) the matches will appear from
      top to bottom with the topmost being selected. Turning it on causes the
      matches to be reversed so the best match is at the bottom and the
      initially selected match is the bottom most. This may be preferable if
      you want the best match to appear in a fixed location on the screen
      but still be near the prompt at the bottom.

As well as the basic options listed above, there are a number of settings that
can be used to override the default key mappings used by Command-T. For
example, to set <C-x> as the mapping for cancelling (dismissing) the Command-T
window, you would add the following to your ~/.vimrc:

  let g:CommandTCancelMap='<C-x>'

Multiple, alternative mappings may be specified using list syntax:

  let g:CommandTCancelMap=['<C-x>', '<C-c>']

Following is a list of all map settings and their defaults:

                              Setting   Default mapping(s)

                                      *g:CommandTBackspaceMap*
              |g:CommandTBackspaceMap|  <BS>

                                      *g:CommandTDeleteMap*
                 |g:CommandTDeleteMap|  <Del>

                                      *g:CommandTAcceptSelectionMap*
        |g:CommandTAcceptSelectionMap|  <CR>

                                      *g:CommandTAcceptSelectionSplitMap*
   |g:CommandTAcceptSelectionSplitMap|  <C-CR>
                                      <C-s>

                                      *g:CommandTAcceptSelectionTabMap*
     |g:CommandTAcceptSelectionTabMap|  <C-t>

                                      *g:CommandTAcceptSelectionVSplitMap*
  |g:CommandTAcceptSelectionVSplitMap|  <C-v>

                                      *g:CommandTToggleFocusMap*
            |g:CommandTToggleFocusMap|  <Tab>

                                      *g:CommandTCancelMap*
                 |g:CommandTCancelMap|  <C-c>
                                      <Esc> (not on all terminals)

                                      *g:CommandTSelectNextMap*
             |g:CommandTSelectNextMap|  <C-n>
                                      <C-j>
                                      <Down>

                                      *g:CommandTSelectPrevMap*
             |g:CommandTSelectPrevMap|  <C-p>
                                      <C-k>
                                      <Up>

                                      *g:CommandTClearMap*
                  |g:CommandTClearMap|  <C-u>

                                      *g:CommandTCursorLeftMap*
             |g:CommandTCursorLeftMap|  <Left>
                                      <C-h>

                                      *g:CommandTCursorRightMap*
            |g:CommandTCursorRightMap|  <Right>
                                      <C-l>

                                      *g:CommandTCursorEndMap*
              |g:CommandTCursorEndMap|  <C-e>

                                      *g:CommandTCursorStartMap*
            |g:CommandTCursorStartMap|  <C-a>

In addition to the options provided by Command-T itself, some of Vim's own
settings can be used to control behavior:

                                               *command-t-wildignore*
  |'wildignore'|                                 string (default: '')

      Vim's |'wildignore'| setting is used to determine which files should be
      excluded from listings. This is a comma-separated list of glob patterns.
      It defaults to the empty string, but common settings include "*.o,*.obj"
      (to exclude object files) or ".git,.svn" (to exclude SCM metadata
      directories). For example:

        :set wildignore+=*.o,*.obj,.git

      A pattern such as "vendor/rails/**" would exclude all files and
      subdirectories inside the "vendor/rails" directory (relative to
      directory Command-T starts in).

      See the |'wildignore'| documentation for more information.


AUTHORS                                         *command-t-authors*

Command-T is written and maintained by Wincent Colaiuta <win@wincent.com>.
Other contributors that have submitted patches include (in alphabetical
order):

  Daniel Hahler
  Lucas de Vries
  Matthew Todd
  Mike Lundy
  Scott Bronson
  Steven Moazami
  Sung Pae
  Victor Hugo Borja
  Zak Johnson

As this was the first Vim plug-in I had ever written I was heavily influenced
by the design of the LustyExplorer plug-in by Stephen Bach, which I understand
is one of the largest Ruby-based Vim plug-ins to date.

While the Command-T codebase doesn't contain any code directly copied from
LustyExplorer, I did use it as a reference for answers to basic questions (like
"How do you do 'X' in a Ruby-based Vim plug-in?"), and also copied some basic
architectural decisions (like the division of the code into Prompt, Settings
and MatchWindow classes).

LustyExplorer is available from:

  http://www.vim.org/scripts/script.php?script_id=1890


WEBSITE                                         *command-t-website*

The official website for Command-T is:

  https://wincent.com/products/command-t

The latest release will always be available from there.

Development in progress can be inspected via the project's Git repository
browser at:

  https://wincent.com/repos/command-t

A copy of each release is also available from the official Vim scripts site
at:

  http://www.vim.org/scripts/script.php?script_id=3025

Bug reports should be submitted to the issue tracker at:

  https://wincent.com/issues


DONATIONS                                       *command-t-donations*

Command-T itself is free software released under the terms of the BSD license.
If you would like to support further development you can make a donation via
PayPal to win@wincent.com:

  https://wincent.com/products/command-t/donations


LICENSE                                         *command-t-license*

Copyright 2010-2011 Wincent Colaiuta. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.


HISTORY                                         *command-t-history*

1.2.1 (30 April 2011)

- Remove duplicate copy of the documentation that was causing "Duplicate tag"
  errors
- Mitigate issue with distracting blinking cursor in non-GUI versions of Vim
  (patch from Steven Moazami)

1.2 (30 April 2011)

- added |g:CommandTMatchWindowReverse| option, to reverse the order of items
  in the match listing (patch from Steven Moazami)

1.1b2 (26 March 2011)

- fix a glitch in the release process; the plugin itself is unchanged since
  1.1b

1.1b (26 March 2011)

- add |:CommandTBuffer| command for quickly selecting among open buffers

1.0.1 (5 January 2011)

- work around bug when mapping |:CommandTFlush|, wherein the default mapping
  for |:CommandT| would not be set up
- clean up when leaving the Command-T buffer via unexpected means (such as
  with <C-W k> or similar)

1.0 (26 November 2010)

- make relative path simplification work on Windows

1.0b (5 November 2010)

- work around platform-specific Vim 7.3 bug seen by some users (wherein
  Vim always falsely reports to Ruby that the buffer numbers is 0)
- re-use the buffer that is used to show the match listing, rather than
  throwing it away and recreating it each time Command-T is shown; this
  stops the buffer numbers from creeping up needlessly

0.9 (8 October 2010)

- use relative paths when opening files inside the current working directory
  in order to keep buffer listings as brief as possible (patch from Matthew
  Todd)

0.8.1 (14 September 2010)

- fix mapping issues for users who have set |'notimeout'| (patch from Sung
  Pae)

0.8 (19 August 2010)

- overrides for the default mappings can now be lists of strings, allowing
  multiple mappings to be defined for any given action
- <Leader>t mapping only set up if no other map for |:CommandT| exists
  (patch from Scott Bronson)
- prevent folds from appearing in the match listing
- tweaks to avoid the likelihood of "Not enough room" errors when trying to
  open files
- watch out for "nil" windows when restoring window dimensions
- optimizations (avoid some repeated downcasing)
- move all Ruby files under the "command-t" subdirectory and avoid polluting
  the "Vim" module namespace

0.8b (11 July 2010)

- large overhaul of the scoring algorithm to make the ordering of returned
  results more intuitive; given the scope of the changes and room for
  optimization of the new algorithm, this release is labelled as "beta"

0.7 (10 June 2010)

- handle more |'wildignore'| patterns by delegating to Vim's own |expand()|
  function; with this change it is now viable to exclude patterns such as
  'vendor/rails/**' in addition to filename-only patterns like '*.o' and
  '.git' (patch from Mike Lundy)
- always sort results alphabetically for empty search strings; this eliminates
  filesystem-specific variations (patch from Mike Lundy)

0.6 (28 April 2010)

- |:CommandT| now accepts an optional parameter to specify the starting
  directory, temporarily overriding the usual default of Vim's |:pwd|
- fix truncated paths when operating from root directory

0.5.1 (11 April 2010)

- fix for Ruby 1.9 compatibility regression introduced in 0.5
- documentation enhancements, specifically targetted at Windows users

0.5 (3 April 2010)

- |:CommandTFlush| now re-evaluates settings, allowing changes made via |let|
  to be picked up without having to restart Vim
- fix premature abort when scanning very deep directory hierarchies
- remove broken |<Esc>| key mapping on vt100 and xterm terminals
- provide settings for overriding default mappings
- minor performance optimization

0.4 (27 March 2010)

- add |g:CommandTMatchWindowAtTop| setting (patch from Zak Johnson)
- documentation fixes and enhancements
- internal refactoring and simplification

0.3 (24 March 2010)

- add |g:CommandTMaxHeight| setting for controlling the maximum height of the
  match window (patch from Lucas de Vries)
- fix bug where |'list'| setting might be inappropriately set after dismissing
  Command-T
- compatibility fix for different behaviour of "autoload" under Ruby 1.9.1
- avoid "highlight group not found" warning when run under a version of Vim
  that does not have syntax highlighting support
- open in split when opening normally would fail due to |'hidden'| and
  |'modified'| values

0.2 (23 March 2010)

- compatibility fixes for compilation under Ruby 1.9 series
- compatibility fixes for compilation under Ruby 1.8.5
- compatibility fixes for Windows and other non-UNIX platforms
- suppress "mapping already exists" message if <Leader>t mapping is already
  defined when plug-in is loaded
- exclude paths based on |'wildignore'| setting rather than a hardcoded
  regular expression

0.1 (22 March 2010)

- initial public release

------------------------------------------------------------------------------
vim:tw=78:ft=help:
plugin/command-t.vim	[[[1
164
" command-t.vim
" Copyright 2010-2011 Wincent Colaiuta. All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" 1. Redistributions of source code must retain the above copyright notice,
"    this list of conditions and the following disclaimer.
" 2. Redistributions in binary form must reproduce the above copyright notice,
"    this list of conditions and the following disclaimer in the documentation
"    and/or other materials provided with the distribution.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
" IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
" ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
" LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
" CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
" SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
" INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
" CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
" ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
" POSSIBILITY OF SUCH DAMAGE.

if exists("g:command_t_loaded")
  finish
endif
let g:command_t_loaded = 1

command CommandTBuffer call <SID>CommandTShowBufferFinder()
command -nargs=? -complete=dir CommandT call <SID>CommandTShowFileFinder(<q-args>)
command CommandTFlush call <SID>CommandTFlush()

if !hasmapto(':CommandT<CR>')
  silent! nmap <unique> <silent> <Leader>t :CommandT<CR>
endif

if !hasmapto(':CommandTBuffer<CR>')
  silent! nmap <unique> <silent> <Leader>b :CommandTBuffer<CR>
endif

function s:CommandTRubyWarning()
  echohl WarningMsg
  echo "command-t.vim requires Vim to be compiled with Ruby support"
  echo "For more information type:  :help command-t"
  echohl none
endfunction

function s:CommandTShowBufferFinder()
  if has('ruby')
    ruby $command_t.show_buffer_finder
  else
    call s:CommandTRubyWarning()
  endif
endfunction

function s:CommandTShowFileFinder(arg)
  if has('ruby')
    ruby $command_t.show_file_finder
  else
    call s:CommandTRubyWarning()
  endif
endfunction

function s:CommandTFlush()
  if has('ruby')
    ruby $command_t.flush
  else
    call s:CommandTRubyWarning()
  endif
endfunction

if !has('ruby')
  finish
endif

function CommandTHandleKey(arg)
  ruby $command_t.handle_key
endfunction

function CommandTBackspace()
  ruby $command_t.backspace
endfunction

function CommandTDelete()
  ruby $command_t.delete
endfunction

function CommandTAcceptSelection()
  ruby $command_t.accept_selection
endfunction

function CommandTAcceptSelectionTab()
  ruby $command_t.accept_selection :command => 'tabe'
endfunction

function CommandTAcceptSelectionSplit()
  ruby $command_t.accept_selection :command => 'sp'
endfunction

function CommandTAcceptSelectionVSplit()
  ruby $command_t.accept_selection :command => 'vs'
endfunction

function CommandTToggleFocus()
  ruby $command_t.toggle_focus
endfunction

function CommandTCancel()
  ruby $command_t.cancel
endfunction

function CommandTSelectNext()
  ruby $command_t.select_next
endfunction

function CommandTSelectPrev()
  ruby $command_t.select_prev
endfunction

function CommandTClear()
  ruby $command_t.clear
endfunction

function CommandTCursorLeft()
  ruby $command_t.cursor_left
endfunction

function CommandTCursorRight()
  ruby $command_t.cursor_right
endfunction

function CommandTCursorEnd()
  ruby $command_t.cursor_end
endfunction

function CommandTCursorStart()
  ruby $command_t.cursor_start
endfunction

ruby << EOF
  # require Ruby files
  begin
    # prepare controller
    require 'command-t/vim'
    require 'command-t/controller'
    $command_t = CommandT::Controller.new
  rescue LoadError
    load_path_modified = false
    ::VIM::evaluate('&runtimepath').to_s.split(',').each do |path|
      lib = "#{path}/ruby"
      if !$LOAD_PATH.include?(lib) and File.exist?(lib)
        $LOAD_PATH << lib
        load_path_modified = true
      end
    end
    retry if load_path_modified

    # could get here if C extension was not compiled, or was compiled
    # for the wrong architecture or Ruby version
    require 'command-t/stub'
    $command_t = CommandT::Stub.new
  end
EOF
