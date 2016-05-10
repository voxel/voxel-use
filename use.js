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

          ret = props.onUse held, target
          if typeof ret == 'undefined'
            # nothing 
          else if typeof ret == 'number' || typeof ret == 'boolean'
            # consume this many
            consumeCount = ret|0
            @inventoryHotbar.takeHeld consumeCount
          else if typeof ret == 'object'
            # (assumed ItemPile instance (TODO: instanceof? but..))
            # replace item - used for voxel-bucket
            # TODO: handle if item count >1? this replaces the whole pile
            @inventoryHotbar.replaceHeld ret

        else if @registry.isBlock held.item
          # 2b. place itemblocks
          newHeld = @useBlock(target, held)
          @inventoryHotbar.replaceHeld newHeld
          @emit 'usedBlock', target, held, newHeld
      else
        console.log 'waving'

  # place a block on target and decrement held
  useBlock: (target, held) ->
    if not target
      # right-clicked air with a block, does nothing
      # TODO: allow 'using' blocks when clicked in air? (no target) (see also: voxel-skyhook)
      console.log 'waving block'
      return held

    # test if can place block here (not blocked by self), before consuming inventory
    # (note: canCreateBlock + setBlock = createBlock, but we want to check in between)
    if not @game.canCreateBlock target.adjacent
      console.log 'blocked'
      return held

    taken = held.splitPile(1)

    # clear empty piles (wart due to itempile mutability, and can't use takeHeld here
    # since held may not necessarily come from the hotbar - if someone else calls us)
    held = undefined if held.count == 0

    if not taken?
      console.log 'nothing in this inventory slot to use'
      return held

    currentBlockID = @registry.getBlockIndex(taken.item)
    @game.setBlock target.adjacent, currentBlockID
    return held

  disable: () ->
    @reach.removeListener 'use', @onInteract

