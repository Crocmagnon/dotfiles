function kns --wraps='kubectl ns'
  kubectl ns $argv;
end
