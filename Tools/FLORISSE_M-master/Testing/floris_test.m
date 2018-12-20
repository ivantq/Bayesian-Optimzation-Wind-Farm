classdef floris_test < matlab.unittest.TestCase
    %floris_test Summary of this class goes here
    %   Detailed explanation goes here
    properties
        florisRunner
    end
    methods(TestMethodSetup)
        function setFolders(testCase)
            % Add the relevant folders to the current path
            import matlab.unittest.fixtures.PathFixture
            
            testCase.applyFixture(PathFixture('../FLORISSE_M/coreFunctions',...
                                              'IncludeSubfolders',true));
            testCase.applyFixture(PathFixture('../FLORISSE_M/layoutDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/ambientFlowDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/controlDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/turbineDefinitions',...
                                              'IncludeSubfolders',true));
            testCase.applyFixture(PathFixture('../FLORISSE_M/submodelDefinitions',...
                                              'IncludeSubfolders',true));
            % Instantiate a layout object with 6 identical turbines
            generic6Turb = generic_6_turb;

            % Use the height from the first turbine type as reference height for theinflow profile
            refheight = generic6Turb.uniqueTurbineTypes(1).hubHeight;
            % Define an inflow struct and use it in the layout, clwindcon9Turb
            generic6Turb.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8, ...
                                                  'PowerLawRefHeight', refheight, ...
                                                  'windDirection', 0, ...
                                                  'TI0', .01);

            % Make a controlObject for this layout
            % controlSet = control_set(layout, 'axialInduction');
            controlSet = control_set(generic6Turb, 'pitch');
            
            % Define subModels
            subModels = model_definition('deflectionModel', 'jimenez',...
                                         'velocityDeficitModel', 'selfSimilar',...
                                         'wakeCombinationModel', 'quadraticRotorVelocity',...
                                         'addedTurbulenceModel', 'crespoHernandez');
            testCase.florisRunner = floris(generic6Turb, controlSet, subModels);
        end
    end
    methods(Test)
        function test_standard_run(testCase)
            import matlab.unittest.constraints.IssuesNoWarnings
            function runner(); testCase.florisRunner.run; end
            testCase.verifyThat(@runner, IssuesNoWarnings)
        end
        function test_again(testCase)
            import matlab.unittest.constraints.IssuesNoWarnings
            function runner(); testCase.florisRunner.run; end
            testCase.verifyThat(@runner, IssuesNoWarnings)
        end
    end
end

