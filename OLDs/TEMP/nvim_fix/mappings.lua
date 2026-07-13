-- ~/.nvim/lua/user/mappings.lua

return {
  -- Modo Normal
  n = {
    -- Salvar buffer (:w)
    ["<C-s>"] = { "<cmd>w<cr>", desc = "Salvar buffer" },

    -- Salvar e sair todos os buffers (:wqa)
    ["<C-q>"] = { "<cmd>wqa<cr>", desc = "Salvar e sair" },    
  },

  -- Modo Insert
  i = {
    -- Salvar buffer (:w)
    ["<C-s>"] = { "<cmd>w<cr>", desc = "Salvar buffer" },

    -- Salvar e sair todos os buffers (:wqa)
    ["<C-q>"] = { "<cmd>wqa<cr>", desc = "Salvar e sair" },
  },

  -- Modo Visual
  v = {
    ["<C-s>"] = { "<cmd>w<cr>", desc = "Salvar buffer" },

    -- Salvar e sair todos os buffers (:wqa)
    ["<C-q>"] = { "<cmd>wqa<cr>", desc = "Salvar e sair" },
  },
}
