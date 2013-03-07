class Numeric
  {
    :year   => 365 * 24 * 3600,
    :month  => 30 * 24 * 3600,
    :week   => 7 * 24 * 3600,
    :day    => 24 * 3600,
    :hour   => 3600,
    :minute => 60,
    :second => 1
  }.each do |m,val|
      respond_to? m or define_method m do 
        self * val
      end
      
      "#{m}s".tap do |plural|
        respond_to? plural or alias_method plural, m
      end

    end    
end