require 'pry/input_completer'

class PryEditline
  def initialize(input, pry = nil)
  end

  def editor
    if defined?(Pry)
      Pry.editor
    else
      ENV.values_at('VISUAL', 'EDITOR').compact.first || 'vi'
    end
  end

  def self.hijack_inputrc
    inputrc = [
      ENV['INPUTRC'],
      (File.expand_path('~/.inputrc') rescue nil),
      '/etc/inputrc'
    ].compact.detect { |x| File.exist?(x) }

    require 'tempfile'
    @file = Tempfile.new('inputrc')
    @file.puts <<-'EOF'
set keymap vi-insert
"\C-a": beginning-of-line
"\C-b": backward-char
"\C-d": delete-char
"\C-e": end-of-line
"\C-f": forward-char
"\C-k": kill-line
"\C-n": next-history
"\C-p": previous-history
"\C-x\C-l": redraw-current-line
"\C-x\C-e": "\C-e  \C-a\t\C-k\C-x\C-l"
"\C-o": "\C-e  \C-a\t\C-k\C-x\C-l"
set keymap vi-command
"o": "A  \C-a\t\C-k\C-x\C-l\e"
"v": "A  \C-a\t\C-k\C-x\C-l\e"
set keymap emacs
"\C-x\C-l": redraw-current-line
"\C-x\C-e": "\C-e  \C-a\t\C-k\C-x\C-l"
"\C-o":     "\C-e  \C-a\t\C-k\C-x\C-l"
$if mode=vi
set keymap vi
$endif
EOF
    @file.puts "$include #{inputrc}" if inputrc
    @file.close
    ENV['INPUTRC'] = @file.path
  end

  def self.completion_proc
    lambda do |s|
      if Readline.respond_to?(:point) && Readline.respond_to?(:line_buffer) &&
          Readline.point == 0 && Readline.line_buffer =~ /  $/
        then
        require 'tempfile'
        Tempfile.open(['readline-','.rb']) do |f|
          f.puts(Readline.line_buffer[0..-3])
          f.close
          system("#{editor} #{f.path}")
          File.read(f.path).chomp
        end
      else
        yield s
      end
    end
  end

  def call(s, options = {})
    require 'tempfile'
    Tempfile.open(['readline-','.rb']) do |f|
      f.puts(Readline.line_buffer[0..-3])
      f.close
      system("#{editor} #{f.path}")
      File.read(f.path).chomp
    end
  end
end

def press_ctrl_x_ctrl_e
  # How to decide current Ctrl-xCtrl-e is pressed use Readline?
  true
end

PryEditline.hijack_inputrc
Pry.config.completer = PryEditline if press_ctrl_x_ctrl_e
