#!/bin/bash

SPATH=/usr/local/Cellar/sshpass/1.06/bin
ZRC=~/.zshrc

# define function
function create_rb {
    cat > sshpass.rb <<EOF
heredoc> require 'formula'

class Sshpass < Formula
  url 'http://sourceforge.net/projects/sshpass/files/sshpass/1.06/sshpass-1.06.tar.gz'
  homepage 'http://sourceforge.net/projects/sshpass'
  sha256 'c6324fcee608b99a58f9870157dfa754837f8c48be3df0f5e2f3accf145dee60'

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make install"
  end

  def test
    system "sshpass"
  end
end
heredoc> EOF
}

function path_mod {
    if grep -qw ^PATH $ZRC; then
        sed -i.bk "/^PATH/s|$|$SPATH|" $ZRC
    else
        sed -i.bk "1iPATH=\$PATH:$SPATH" $ZRC
    fi
}

# Main area
create_rb
brew install sshpass.rb
path_mod
sourc $ZRC
echo
