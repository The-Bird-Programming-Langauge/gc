(module
  	(import "env" "print" (func $print (param i32)))  (export "main" (func $main))
  	(memory $memory 1)
  	(export "memory" (memory $memory))
	(global $null i32 (i32.const 0))
	(global $listHead (mut i32) (i32.const 0)) ;; head is null

	;; initialize free list
	(func $initList
		i32.const 1 ;; zero is reserved for null
		i32.const 65535 ;; 64KB
		call $createBlock
	)

	;; block structure - 12 bytes
	;; size - 4 bytes - includes block structure size
	;; next - 4 bytes
    ;; free - 4 bytes
	(func $createBlock (param $ptr i32) (param $size i32)
		;; set size
		local.get $ptr
		local.get $size
		call $setSize

		;; set free
		local.get $ptr
		i32.const 1
		call $setFree

		;; set next
		local.get $ptr
		global.get $listHead
		call $setNext

		;; update listHead
		local.get $ptr
		global.set $listHead
	)

    ;; block.size
	(func $getSize (param $block i32) (result i32)
		local.get $block
		i32.load
		return
	)

    ;; block.next
	(func $getNext (param $block i32) (result i32)
		local.get $block
		i32.const 4
		i32.add
		i32.load
		return
	)

    ;; block.size = size
	(func $setSize (param $block i32) (param $size i32)
		local.get $block
		local.get $size
		i32.store
	)

    ;; block.size = size
	(func $setNext (param $block i32) (param $next i32)
		local.get $block
		i32.const 4
		i32.add
		local.get $next
		i32.store
	)

    ;; block.free
    (func $getFree (param $block i32) (result i32)
        local.get $block
        i32.const 8
        i32.add
        i32.load
        return
    )

    ;; block.free = free
    (func $setFree (param $block i32) (param $free i32)
        local.get $block
        i32.const 8
        i32.add
        local.get $free
        i32.store
    )

    (func $malloc (param $size i32) (result i32 (;pointer;))
        (local $current i32)

        ;; set current to head
        global.get $listHead
        local.set $current

        (loop $loop
            ;; if current.size >= size + 12
			(if (i32.eq 
					(call $getFree (local.get $current))
					(i32.const 1))
				(then 
					(if (i32.ge_u 
							(call $getSize (local.get $current)) 
							(i32.add (local.get $size) (i32.const 12)))
						(then ;; found block
							;; if current.size >= size + 36 
							;; 12 for current block info, 12 for next block info, 12 for next block free space
							(if (i32.ge_u
								(call $getSize (local.get $current))
								(i32.add (local.get $size) (i32.const 36)))
								(then ;; split block
									;; create new block
									local.get $current
									i32.const 12
									i32.add
									local.get $size
									i32.add ;; pointer to new block
									local.get $current
									call $getSize
									i32.const 12
									i32.sub
									local.get $size
									i32.sub ;; size of new block
									call $createBlock

									;; update current block size
									local.get $current
									local.get $size
									i32.const 12
									i32.add
									call $setSize

									;; current.free = 0
									local.get $current
									i32.const 0
									call $setFree

									;; return current + 12
									local.get $current
									i32.const 12
									i32.add
									return
								)
								(else ;; use whole block
									;; current.free = 0
									local.get $current
									i32.const 0
									call $setFree

									;; return current + 12
									local.get $current
									i32.const 12
									i32.add
									return
								)
							)
						)
					)
				)
			)

            ;; current = current.next
            local.get $current
            call $getNext
            local.set $current

			;; if current == null
			local.get $current
			global.get $null
			i32.ne
			br_if $loop
        )

		i32.const 69420
		call $print


		i32.const 0
		return
    )

    (func $free (param $ptr i32)
		local.get $ptr
		i32.const 1
		call $setFree
    )


	(func $printList 
		(local $current i32)

		;; set current to head
		global.get $listHead
		local.set $current

		(loop $loop
			;; print current.size
			local.get $current
			call $getSize
			call $print

			;; print current.free
			local.get $current
			call $getFree
			call $print

			;; current = current.next
			local.get $current
			call $getNext
			local.set $current

			;; if current == null
			local.get $current
			global.get $null
			i32.ne
			br_if $loop
		)
	)

	(func $main
		(local $first i32)
		(local $second i32)
		(local $third i32)
		(local $fourth i32)

		call $initList
		;; allocate 10 bytes
		i32.const 10
		call $malloc
		local.tee $first
		call $print

		;; allocate 20 bytes
		i32.const 20
		call $malloc
		local.tee $second
		call $print

		;; allocate 30 bytes
		i32.const 30
		call $malloc
		local.tee $third
		call $print

		;; allocate 40 bytes
		i32.const 40
		call $malloc
		local.tee $fourth
		call $print

		;; print list
		call $printList

		i32.const 69420
		call $print

		;; free second
		local.get $second
		call $free

		;; print list
		call $printList
	)
)