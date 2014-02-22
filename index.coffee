EventEmitter = (require 'events').EventEmitter

module.exports = (game, opts) ->
  return new Use(game, opts)

module.exports.pluginInfo =
  loadAfter: ['voxel-reach', 'voxel-registry', 'voxel-inventory-hotbar']

class Use extends EventEmitter
  constructor: (@game, opts) ->

    @reach = game.plugins?.get('voxel-reach') ? throw new Error('voxel-use requires "voxel-reach" plugin')
    @registry = game.plugins?.get('voxel-registry') ? throw new Error('voxel-use requires "voxel-registry" plugin')
    @inventoryHotbar = game.plugins?.get('voxel-inventory-hotbar') ? throw new Error('voxel-use requires "voxel-inventory-hotbar" plugin') # TODO: move held to voxel-carry?
    @enable()

  enable: () ->
    @reach.on 'use', @onInteract = (target) =>
      # 1. block interaction
      if target?.voxel? and !@game.buttons.crouch
        clickedBlockID = @game.getBlock(target.voxel)  # TODO: should voxel-reach get this?
        clickedBlock = @registry.getBlockName(clickedBlockID)

        props = @registry.getBlockProps(clickedBlock)
        if props.onInteract?
          # this block handles its own interaction
          # TODO: redesign this? cancelable event?
          preventDefault = props.onInteract(target)
          return if preventDefault

      # 2. use items in hand
      held = @inventoryHotbar?.held()
     
      if held?.item
        props = @registry.getItemProps(held.item)
        if props?.onUse
          # 2a. use items

          # TODO: other interactions depending on item (ex: click button, check target.sub; or other interactive blocks)
          consumed = props.onUse held, target
          if consumed
            @inventoryHotbar.takeHeld consumed|0

        else if @registry.isBlock held.item
          # 2b. place itemblocks
          
          # test if can place block here (not blocked by self), before consuming inventory
          # (note: canCreateBlock + setBlock = createBlock, but we want to check in between)
          if not @game.canCreateBlock target?.adjacent # TODO: allow 'using' blocks when clicked in air? (no target)
            console.log 'blocked'
            return

          taken = @inventoryHotbar.takeHeld(1)
          if not taken?
            console.log 'nothing in this inventory slot to use'
            return

          currentBlockID = @registry.getBlockID(taken.item)
          @game.setBlock target.adjacent, currentBlockID
      else
        console.log 'waving'

  disable: () ->
    @reach.removeListener 'use', @onInteract

