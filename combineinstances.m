function combo = combineinstances(array1,array2)

combo = {0,0,0,0,0,0,0,0};

i = 1;
while i < 9
    a = [array1{i};array2{i}];
    combo(i) = {a};
    i = i + 1;
end

