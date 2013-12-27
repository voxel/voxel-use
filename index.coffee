# vim: set shiftwidth=2 tabstop=2 softtabstop=2 expandtab:

EventEmitter = (require 'events').EventEmitter

module.exports = (game, opts) ->
  return new Use(game, opts)

module.exports.pluginInfo =
  loadAfter: ['reach', 'registry', 'inventory-hotbar']

class Use extends EventEmitter
  constructor: (@game, opts) ->

    @reach = game.plugins?.all.reach ? throw 'voxel-use requires "voxel-reach" plugin'
    @registry = game.plugins?.all.registry ? throw 'voxel-use requires "voxel-registry" plugin'
    @inventoryHotbar = game.plugins?.all['inventory-hotbar'] ? throw 'voxel-use requires "voxel-inventory-hotbar" plugin'
    @enable()

  enable: () ->
    @reach.on 'interact', @onInteract = (target) =>
      if not target
        console.log 'waving'
        return

      # TODO: major refactor

      # 1. block interaction
      if target.voxel? and !@game.buttons.crouch
        clickedBlockID = @game.getBlock(target.voxel)  # TODO: should voxel-reach get this?
        clickedBlock = @registry.getBlockName(clickedBlockID)

        props = @registry.getBlockProps(clickedBlock)
        if props.onInteract?
          # this block handles its own interaction
          # TODO: redesign this? cancelable event?
          preventDefault = props.onInteract()
          return if preventDefault

      if @registry.isBlock(@inventoryHotbar.held()?.item)
        # 2. place blocks

        # test if can place block here (not blocked by self), before consuming inventory
        # (note: canCreateBlock + setBlock = createBlock, but we want to check in between)
        if not @game.canCreateBlock target.adjacent
          console.log 'blocked'
          return

        taken = @inventoryHotbar.takeHeld(1)
        if not taken?
          console.log 'nothing in this inventory slot to use'
          return

        currentBlockID = @registry.getBlockID(taken.item)
        @game.setBlock target.adjacent, currentBlockID
      else
        # 3. TODO: use items (if !isBlock)
        # TODO: other interactions depending on item (ex: click button, check target.sub; or other interactive blocks)
        console.log 'use item',@inventoryHotbar.held()

  disable: () ->
    @reach.removeListener 'interact', @onInteract

