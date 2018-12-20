function [ flowField ] = compute_flow_field(flowField, layout, turbineResults, yawAngles, avgWs, fixYaw, wakeCombinationModel)
    % Sort turbine and wake structs by WF
    if fixYaw
        % tpr stands for TurbinePreRegion. It is the amount of meters in front
        % of a turbine where the flowfield will take into account a turbine
        tpr = max([layout.uniqueTurbineTypes.rotorRadius])/2;
    else
        tpr = 0;
    end
    
    % Compute the windspeed at a cutthrough of the wind farm at every x-coordinate
    for xSample = flowField.X(1,:,1)
        % Select the upwind turbines and store them in a struct
        uwTurbIfIndexes = find(xSample-(layout.locWf(:,1)-tpr)>=0);
        if ~isempty(uwTurbIfIndexes)
            % compute the upwind turbine distance with respect to xSample
            deltaXs = xSample - layout.locWf(uwTurbIfIndexes, 1);
            
            % delta Y and Z with respect to wake centerline
            dY_wc = zeros([size(squeeze(flowField.U(:,1,:))) length(uwTurbIfIndexes)]);
            dZ_wc = zeros([size(squeeze(flowField.U(:,1,:))) length(uwTurbIfIndexes)]);
            
            % Compute the velocity at every point by adding the velocity
            % deficits.^2 and taking the root
            sumKed = zeros(size(squeeze(flowField.U(:,1,:))));
            for turbNum = 1:length(uwTurbIfIndexes)
                turbIfIndex = uwTurbIfIndexes(turbNum);
                curWake = turbineResults(turbIfIndex).wake;
                % Find the index of this xSample in the wake centerline
                [dy, dz] = curWake.deflection(xSample-layout.locWf(turbIfIndex,1));
                dY_wc(:,:,turbNum) = flowField.Y(:,1,:)-dy-layout.locWf(turbIfIndex,2);
                dZ_wc(:,:,turbNum) = flowField.Z(:,1,:)-dz-layout.locWf(turbIfIndex,3);
                
                % Make a mask where the wake exists
                mask = curWake.boundary(deltaXs(turbNum),dY_wc(:,:,turbNum),dZ_wc(:,:,turbNum));
                if fixYaw
                    % Extend the mask with the location of the swept area
                    mask = mask.*(((squeeze(flowField.Y(:,1,:))- ...
                        layout.locWf(turbIfIndex,2))*tan(-yawAngles(turbIfIndex)))<deltaXs(turbNum));
                    if deltaXs(turbNum)<=0
                        % If the coordinates are in front of the turbine
                        % use the velocity deficit in the wake.
                        velDef = mask.*curWake.deficit(1, 0, 0);
                    else
                        % Behind the turbine compute the wake
                        velDef = mask.*curWake.deficit(deltaXs(turbNum), dY_wc(:,:,turbNum), dZ_wc(:,:,turbNum));
                    end
                else
                    % Compute the wake deficit
                    velDef = mask.*curWake.deficit(deltaXs(turbNum), dY_wc(:,:,turbNum), dZ_wc(:,:,turbNum));
                end
                % Sum the velocity deficits according to the wake model
                sumKed = sumKed+wakeCombinationModel(squeeze(flowField.U(:,1,:)), ...
                    avgWs(turbIfIndex), 1-velDef);
            end
            flowField.U(:,flowField.X(1,:,1)==xSample,:) = squeeze(flowField.U(:,1,:))-sqrt(sumKed);
        end
    end
end