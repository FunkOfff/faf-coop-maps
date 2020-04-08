version = 3 -- Lua Version. Dont touch this
ScenarioInfo = {
    name = "UEF Mission 2 - Snow Blind - FunkOff edit",
    description = "While you were busy on Capella, the Aeon pushed out of the Quarantine Zone and attacked our positions on Luthien. Our forces there are holding their own, but they will fall unless they're reinforced.",
    preview = '',
    map_version = 1,
    type = 'campaign_coop',
    starts = true,
    size = {512, 512},
    reclaim = {234276.2, 225600},
    map = '/maps/scca_coop_e02.v0020f/SCCA_Coop_E02.scmap',
    save = '/maps/scca_coop_e02.v0020f/SCCA_Coop_E02_save.lua',
    script = '/maps/scca_coop_e02.v0020f/SCCA_Coop_E02_script.lua',
    norushradius = 0,
    Configurations = {
        ['standard'] = {
            teams = {
                {
                    name = 'FFA',
                    armies = {'Player1', 'Aeon', 'AllyResearch', 'AllyCivilian', 'AeonNeutral', 'Player2', 'Player3', 'Player4'}
                },
            },
            customprops = {
            },
        },
    },
}
