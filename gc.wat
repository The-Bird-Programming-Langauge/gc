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
		call $createNode
	)

	;; Node structure
	;; size - 4 bytes
	;; next - 4 bytes
	(func $createNode (param $ptr i32) (param $size i32)
		;; set size
		local.get $ptr
		local.get $size
		call $setSize

		;; set next
		local.get $ptr
		global.get $listHead
		call $setNext

		;; update listHead
		local.get $ptr
		global.set $listHead
	)

	(func $getSize (param $node i32) (result i32)
		local.get $node
		i32.load
		return
	)

	(func $getNext (param $node i32) (result i32)
		local.get $node
		i32.const 4
		i32.add
		i32.load
		return
	)

	(func $setSize (param $node i32) (param $size i32)
		local.get $node
		local.get $size
		i32.store
	)

	(func $setNext (param $node i32) (param $next i32)
		local.get $node
		i32.const 4
		i32.add
		local.get $next
		i32.store
	)

	(func $printList
		(local $current i32) ;; pointer to current node
		global.get $listHead
		local.set $current

		(loop $loop
			local.get $current
			call $getSize
			call $print

			local.get $current
			call $getNext
			local.set $current

			local.get $current
			global.get $null

			i32.ne
			br_if $loop
		)

		return
	)

	(func $removeNode (param $node i32)
		(local $current i32)
		(local $prev i32) ;; initialize to null
		(local $next i32) ;; initialize to null

		(if
			(i32.eq
				(local.get $node)
				(global.get $listHead)
			)
			(then 
			return)
		)

		global.get $listHead
		local.set $current

		(loop $loop
			(if 
				(i32.eq
					(local.get $current)
					(local.get $node)
				)
				(then ;; found the node
					(if 
						(i32.eq
							(local.get $prev)
							(global.get $null)
						)
						(then ;; if prev is null, then node is the head
							;; update listHead
							local.get $current
							call $getNext
							global.set $listHead

							return
						)
						(else ;; if prev is not null
							;; update next of prev
							local.get $prev
							local.get $current
							call $getNext
							call $setNext

							return
						)
					)
				)
			)

			;; update prev
			local.get $current
			local.set $prev

			;; update current
			local.get $current
			call $getNext
			local.set $current

			;; if current is null, then node is not in the list
			local.get $current
			global.get $null
			i32.ne
			br_if $loop
		)
	)

	(func $free (param $address i32) (param $size i32)
		local.get $address
		local.get $size
		call $createNode

		return
	)


	(func $allocate (param $size i32) (result i32)
		(local $current i32)
		(local $newSize i32)

		global.get $listHead
		local.set $current

		(loop $loop
			local.get $current
			call $getSize
			local.get $size
			i32.ge_s
			(if
				(then
					;; found the node
					local.get $current
					call $getSize
					local.get $size
					i32.sub
					local.set $newSize

					;; if size is greater than 4, then split the node
					(if
						(i32.ge_s
							(local.get $newSize)
							(i32.const 4)
						)
						(then
							;; udpate size of current node
							local.get $current
							local.get $newSize
							call $setSize


							;; return first free address
							local.get $current
							call $getSize
							local.get $current
							i32.add
							return
						)
					)

					;; remove the node from the list
					local.get $current
					call $removeNode

					;; return the current node
					local.get $current
					return
				)
			)

			;; else move to next node
			local.get $current
			call $getNext
			local.set $current

			local.get $current
			global.get $null
			i32.ne
			br_if $loop
		)

		i32.const 0
		return
	)

	(func $main
		(local $first i32)
		(local $second i32)
		(local $third i32)

		call $initList

		;; allocate 10 bytes
		i32.const 10
		call $allocate
		local.set $first

		;; allocate 20 bytes
		i32.const 20
		call $allocate
		local.set $second
		
		;; allocate 30 bytes
		i32.const 30
		call $allocate
		local.set $third

		;; print list
		call $printList

		;; free second
		local.get $second
		i32.const 20
		call $free

		;; print list
		call $printList

		;; allocate 10 bytes
		i32.const 10	
		call $allocate

		;; print list
		call $printList

		return
	)
)