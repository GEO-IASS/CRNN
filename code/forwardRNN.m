function [train test] = forwardRNN(train, test, params)
% In this function we take the final output from the CNN and stack an RNN
% ontop of the final responses. The children will be pooled spatially
% accross all maps.

% hard code the receptive field size (or child size) of each RNN
params.RFS = [3 3];
rnn = initRandomRNNWeights(params, size(train.data,2));

% forward prop training data
disp('Forward Prop Train...');
% output : numTrain x numRNN x numHid
train.data = forward(train.data, rnn, params);
% forward prop testing data
disp('Forward Prop Test...');
test.data = forward(test.data, rnn, params);

train.data = train.data(:,:)';
test.data = test.data(:,:)';


function rnnData = forward(data, rnn, params)
data = permute(data,[2 3 4 1]);
[numMaps, rows, cols, numImgs] = size(data);

RFS = params.RFS;
numRNN = params.numRNN;
assert(rows == cols);
depth = floor(log(rows)/log(RFS(1)) + 0.5);

% ensure a balanced tree is possible with these sizes
assert(mod(log(rows)/log(params.RFS(1)),1) < 1e-15);
assert(mod(log(cols)/log(params.RFS(2)),1) < 1e-15);

rnnData = zeros(numRNN, numMaps,numImgs);
for r = 1:numRNN
    if mod(r,8)==0
        disp(['RNN: ' num2str(r)]);
    end
    W = squeeze(rnn.W(r,:,:));
    tree = data;
    for layer = 1:depth
        newTree = zeros(numMaps,size(tree,2)/RFS(1),size(tree,3)/RFS(2),numImgs);
        rc = 1;
        for row = 1:RFS(1):size(tree,2)
            cc = 1;
            for col = 1:RFS(2):size(tree,3)
                newTree(:,rc,cc,:) = tanh(W * reshape(tree(:,row:row+RFS(1)-1,col:col+RFS(2)-1,:),[],numImgs));
                cc = cc + 1;
            end
            rc = rc + 1;
        end
        tree = newTree;
    end
    rnnData(r,:,:) = squeeze(tree);
end

rnnData = permute(rnnData, [3 1 2]);


function rnn = initRandomRNNWeights(params, numMaps)
rnn.W = zeros(params.numRNN, numMaps, numMaps*prod(params.RFS));
for i = 1:params.numRNN
    rnn.W(i,:,:) = -0.11 + 0.22 * rand(numMaps, numMaps*prod(params.RFS));
end











